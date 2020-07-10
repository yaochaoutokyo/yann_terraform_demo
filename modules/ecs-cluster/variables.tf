variable "subnet_id" {
  type        = string
  description = "ID of subnet"
}

variable "security_groups" {
  type        = list(string)
  description = "List of security groups"
}

variable "az" {
  type        = string
  description = "Availability zone"
}

variable "ami" {
  type        = string
  description = "AMI to use. If not specified, use latest ecs optimized AMI for instance type."
  default     = null
}
variable "key_name" {
  type        = string
  description = "Name of ssh key"
}

variable "template_dir" {
  description = "Path to template dir"
}

variable "instance_type" {
  type        = string
  description = "Instance type to use"
}

variable "instance_count" {
  description = "Integer for instance_count"
}

variable "name" {
  type        = string
  description = "name"
}

variable "ebs_volumes" {
  type = list(map(any))
  # device_name = string 
  # snapshot_id = string 
  # size = number 
  # type = string
  description = "Optional list of EBS volumes to be mounted. Either snapshot_id or size / type have to be specified for each. snapshot_id has priority if both are specified. Input parameters: device_name: string / mount_dir: string snapshot_id: string / size: number / type: string"
  default     = null
}

variable "efs_dir" { 
  type = string 
  description = "If provided, an Elastic File System resource will be created and all instances will mount the EFS on the provided directory"
  default = "" 
}

variable "ebs_optimized" {
  type        = bool
  description = "Whether instance should be ebs optimized"
  default     = false
}

variable "lifecycle_policy" {
  type = list(object({
    name = string
    rule = map(string)
  }))
  description = "List of lifecycle policies for snapshots created for the volume. Rule is map with possible keys: cron_expression (string), interval (string), times (comma separated list as string), count (string). https://docs.aws.amazon.com/dlm/latest/APIReference/API_CreateLifecyclePolicy.html"
  default     = []
}

variable "environment" {
  type        = string
  description = "Environment of resources"
}

variable "instance_profile" {
  type        = string
  description = "IAM instance profile to assume on EC2 instances"
  default     = null
}

variable "user_data_extra" {
  type        = string
  description = "Extra command to be appended to user data"
  default     = ""
}

variable "eip" {
  type        = bool
  description = "Whether to add an EIP to the instance"
  default     = false
}

variable "auto_scaling_group" {
  type = object({
    desired_capacity = number
    min_size         = number
    max_size         = number
    target_groups    = list(string)
    policies = object({
      up = list(object({
        metric    = string
        threshold = number
        cooldown  = number
      }))
      down = list(object({
        metric    = string
        threshold = number
        cooldown  = number
      }))
    })
  })
  description = "Configuration for auto scaling group. If not provided, no auto scaling group will be created. If set, auto scaling group will be created instead of regular EC2 instances. Supported metrics are: MEM, CPU, ALB. If ecs_managed is true, no policies and alarms will be created."
  default     = null
}


variable "capacity_provider" {
  type = bool 
  description = "Whether to use a custom capacity provider or EC2. Custom capacity provider will scale auto scaling groups."
  default = false
}

variable "capacity_target" {
  type = number 
  description = "Target for resource reservations. Default is 100"
  default = 100
}

variable "enable_consul" {
  type = bool 
  description = "Whether or not to run consul agents on the host instances"
  default = false
}

variable "ipv6_address_count" {
  type = number 
  description = "How many IPv6 addresses to assign to the instances of the cluster"
  default = 1
}

variable "tags" {
  type = map(any)
  description = "Optional map of tags to add to the instances"
  default = {}
}