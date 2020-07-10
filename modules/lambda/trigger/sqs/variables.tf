# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "queue_name" {
  type        = string
  description = "the name of trigger sqs, if it is empty that means don't add SQS trigger"
}

variable "function_name" {
  type        = string
  description = "The name or the ARN of the Lambda function that will be subscribing to events. "
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "visibility_timeout" {
  default     = 30
  description = "The visibility timeout(second) of the SQS"
}

variable "batch_size" {
  default     = 10
  description = "The largest number of records that Lambda will retrieve from your event source at the time of invocation. Defaults to 10 for SQS."
}

variable "event_source_mapping_enabled" {
  default     = true
  description = "Determines if the mapping will be enabled on creation. Defaults to true."
}

variable "tags" {
  default     = {}
  description = "A mapping of tags to assign to the object."
  type        = map(string)
}