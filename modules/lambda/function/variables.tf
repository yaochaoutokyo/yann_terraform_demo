# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "function_name" {
  description = "A unique name for your Lambda Function."
  type        = string
}

variable "event_age_in_seconds" {
  default     = 100
  description = "Maximum age of a request that Lambda sends to a function for processing in seconds. Valid values between 60 and 21600."
  type        = number
}

variable "retry_attempts" {
  default     = 2
  description = "Maximum number of times to retry when the function returns an error. Valid values between 0 and 2. Defaults to 2."
  type        = number
}

variable "s3_bucket" {
  description = "The S3 bucket of code.zip"
  type        = string
}

variable "s3_key" {
  description = "The S3 key of code.zip"
  type        = string
}

variable "runtime" {
  description = "See Runtimes for valid values."
  type        = string
}
variable "handler" {
  description = "The function entrypoint in your code."
  type        = string
}

variable "role_arn" {
  description = "IAM role attached to the Lambda Function. This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128."
  type        = number
  default     = 128
}
variable "concurrency" {
  description = "The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. "
  type        = number
  default     = -1
}
variable "lambda_timeout" {
  default     = 30
  description = "The amount of time your Lambda Function has to run in seconds. Defaults to 5"
  type        = number
}

variable "description" {
  default     = ""
  description = "Description of what your Lambda Function does."
  type        = string
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the object."
  type        = map(string)
}

variable "vpc_config" {
  description = "Provide this to allow your function to access your VPC (if both 'subnet_ids' and 'security_group_ids' are empty then vpc_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details)."
  type        = map(list(string))
  default     = {}
}


variable "environment" {
  description = "Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries"
  type        = map(map(string))
  default     = {}
}

variable "publish" {
  default     = false
  description = "Whether to publish creation/change as new Lambda Function Version. Defaults to true."
  type        = bool
}

variable "log_retention" {
  default     = 1
  description = "Specifies the number of days you want to retain log events in the specified log group."
  type        = number
}
