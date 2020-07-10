variable "name" {
  type        = string
  description = "name"
}

variable "environment" {
  type        = string
  description = "environment"
}
variable "cluster_name" {
  type        = string
  description = "Name of cluster"
}

variable "volume" {
  type = list(object({
    name      = string
    host_path = string
  }))
  description = "Optional volume struct"
  default     = null
}

variable "docker_volume_configuration" {
  type = object({
    name          = string
    scope         = string
    autoprovision = bool
    driver        = string
    driver_opts   = map(string)
    labels        = map(string)
  })
  description = "Optional docker volume"
  default     = null
}

variable "template_dir" {
  type        = string
  description = "Relative path to the template directory"
}

variable "container_image" {
  type        = string
  description = "Image of the container. If a tag is specified, that tag will be used. Else, either master or develop tags will be used, based on the environment."
}

variable "container_cpu" {
  type        = number
  description = "Hard CPU specification of container"
  default = null
}

variable "container_cpu_soft" {
  type        = number
  description = "Soft CPU specification of container"
  default = null
}

variable "container_memory" {
  type        = number
  description = "Hard memory specification of container"
  default = null
}

variable "container_memory_soft" {
  type        = number
  description = "Soft memory specification of container"
  default = null
}

variable "container_command" {
  type        = list(string)
  description = "List of commands, as separated by whitespace"
  default     = []
}

variable "container_mount_points" {
  type = list(object({
    sourceVolume  = string
    containerPath = string
  }))
  description = "List of mount points"
  default     = []
}

variable "container_privileged" {
  type        = bool
  description = "Give container privileged access"
  default     = false
}

variable "container_ulimits" {
  type        = list(object({
    softLimit = number 
    hardLimit = number 
    name = string
  }))
  description = "Ulimits of taskd ef"
  default     = []
}

variable "container_port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  description = "List of port mappings"
  default     = []
}

variable "container_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Environment variables"
  default     = []
}

variable "container_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "Sensitive environment variables"
  default     = []
}

variable "container_dns_servers" { 
  type = list(string)
  description = "List of DNS servers to pass to containers"
  default = []
}

variable "iam_role" {
  type        = string
  description = "Optional ARN of IAM role for the service"
  default     = null
}

variable "execution_role_arn" {
  type        = string
  description = "Optional ARN of IAM role for tasks"
  default     = ""
}


variable "minimum_healthy" {
  type        = number
  description = "Percentage of minimum healthy tasks"
  default     = 100
}
variable "maximum_healthy" {
  type        = number
  description = "Percentage of maximum healthy tasks"
  default     = 200
}

variable "blue_green_deployment" {
  type = object({
    target_name = string
    lb_listener_arns = list(string)
  })
  description = "Optional blue green deployment configuration. target_name is coin type as used when creating ALB. target_name will be used for blue/green target groups."
  default = null
}


variable "load_balancer" {
  type = object({
    target_group_arn = string
    container_port   = number
  })
  description = "Load balancer configuration"
  default     = null
}


variable "desired_count" {
  type        = number
  description = "Desired count for this service. Due to auto scaling, desired count has to be updated through AWS Console"
  default     = 1
}


variable "network_mode" {
  type        = string
  description = "Network mode to use for the task. Default is bridge"
  default     = "bridge"
}

variable "network_configuration" {
  type = object({
    subnet_ids      = list(string)
    security_groups = list(string)
  })
  description = "Network configuration of the service. Required if network mode is awsvpc"
  default     = null
}


variable "auto_scaling" {
  type = object({
    max_capacity       = number
    min_capacity       = number
    metric             = string
    target_value       = number
    scale_in_cooldown  = number
    scale_out_cooldown = number
  })
  description = "Configuration of auto scaling for the service. Valid values for metric are: CPU, MEM, ALB"
  default     = null
}



variable "placement_strategy" {
  type = object({
    type  = string
    field = string
  })
  description = "Placement strategy for tasks. Valid type values are: binpack, random, spread. For binpack, fields are: cpu, memory. For spread: instanceId. For random: null."
  default     = null
}
