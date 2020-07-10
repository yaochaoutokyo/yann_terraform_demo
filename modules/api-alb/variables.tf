variable "security_groups" {
  type        = list(string)
  description = "List of security group IDs"
}

variable "vpc" {
  type        = string
  description = "ID of VPC to run ALB in"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet IDs"
}

variable "environment" {
  type        = string
  description = "Environment. Either DEV or PROD."
}


variable "blue_green" {
  type        = bool
  description = "Whether to support blue/green deplyments by creating blue/green target groups"
}

variable "targets" {
  type = list(object({
    name         = string
    health_check = string
    address      = string
  }))
  description = "The targets. Name is name of target group, health_check is path to health check on. address is condition for target group in listener."
}

variable "internal" {
  type        = bool
  description = "Whether to create an intranet or internet facing ALB"
  default     = true
}

variable "idle_timeout" {
  type        = number
  description = "Connection idle timeout (second)"
  default     = 60
}

variable "type" {
  type = string 
  description = "Target group registration type. Default is instance"
  default = "instance"
}