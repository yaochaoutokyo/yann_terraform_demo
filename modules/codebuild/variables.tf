# To be removed after migrating to CodePipeline
variable "BITBUCKET_TOKEN" {
  type = string
  default = "" 
}

# To be removed after migrating to CodePipeline
variable "BITBUCKET_USER" {
  type = string
  default = ""
}

variable "name" {
  type        = string
  description = "Name of the code build project"
}

variable "cache_bucket" {
  type        = string
  description = "Cache bucket to use for caching"
}

variable "environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Environment variables"
  default     = []
}

variable "repository_url" {
  type        = string
  description = "URL of the bitbucket repository"
}


variable "branch_pattern" {
  type        = string
  description = "Regex pattern that will trigger the build"
  default     = "^refs/heads/(master|develop)$"
}

variable "event_triggers" {
  type = list(string)
  description = "Events that should trigger the CodeBuild project. Possible values are: PUSH, PULL_REQUEST_CREATED, PULL_REQUEST_UPDATED, PULL_REQUEST_REOPENED, PULL_REQUEST_MERGED"
  default = ["PUSH"]
}

variable "service_role" {
  type        = string
  description = "Name of service role"
}


variable "buildspec" {
  type        = string
  description = "Buildspec required for building. Default is buildspec file in root directory of the project."
  default     = ""
}

variable "auth_arn" {
  type        = string
  description = "ARN of auth resource"
}

variable "image" {
  type        = string
  description = "Optional image. Defaults to aws/codebuild/amazonlinux2-x86_64-standard:2.0"
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
}

variable "create" {
  type = bool 
  default = true
}

variable "artifacts" {
  type = object({
    bucket = string
    path = string
  })
  description = "Artifacts bucket. Location is bucket name, path is prefix."
  default = null 
}