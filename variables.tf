variable "namespace" {
  type        = string
  default     = "s3backend"
  description = "The project namespace to use for unique resource naming"
}
variable "principal_arns" {
  type        = list(string)
  default     = null
  description = "A list of principal arns allowed to assume the IAM role"
}
variable "force_destroy_state" {
  type        = bool
  default     = true
  description = "Force destroy the s3 bucket containing state files?"
}
