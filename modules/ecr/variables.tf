variable "name" {
  type        = string
  description = "Name of ECR"
}

variable "mutability" {
  type        = string
  description = "Mutability of ECR"
  default     = "MUTABLE"
}