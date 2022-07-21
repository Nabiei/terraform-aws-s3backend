# create S3 bucket for Terraform S3 backend to store state file
data "aws_region" "current" {}

resource "random_string" "rand_str" { # generate random string for name space
    length      = 24
    special     = false
    upper       = false
}

locals {
    namespace = substr(join("-", [var.namespace, random_string.rand_str.result]), 0, 24)
}

resource "aws_resourcegroups_group" "resource_group" { # group resources by tags with "key":"key_name", "value":"your_value" 
    name        = "${local.namespace}-group"
    resource_query {
        query = <<-JSON
        {
            "ResourceTypeFilters": ["AWS::AllSupported"],
            "TagFilters": 
            [{
                "Key": "ResourceGroup",
                "Values": ["${local.namespace}"]
            }]
        }
        JSON
    } 
}

resource "aws_kms_key" "kms_key" {
    tags    = {ResourceGroup = local.namespace}
}


resource "aws_s3_bucket" "s3_bucket" {
    bucket          = "${local.namespace}-state-bucket"
    force_destroy   = var.force_destroy_state
    #versioning {enabled=true} # deprecated
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm       = "aws:kms"
                kms_master_key_id   = aws_kms_key.kms_key.arn
            }
        }
    }
    tags = {
        ResourceGroup = local.namespace
    }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = "${local.namespace}-state-bucket"
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "dynamodb_table" {
    name            = "${local.namespace}-state-lock"
    hash_key        = "LockID"
    billing_mode    = "PAY_PER_REQUEST"
    attribute {
        name = "LockID"
        type = "S"
    }
    tags = {
        ResourceGroup = local.namespace
    }
}
