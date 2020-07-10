data "aws_caller_identity" "current" {}


resource "aws_codebuild_project" "codebuild" {
  count = var.create == true ? 1 : 0 

  name           = var.name
  build_timeout  = "60"
  queued_timeout = "120"


  service_role = var.service_role

  dynamic artifacts {
    for_each = var.artifacts == null ? [var.artifacts] : []
    content {
      type = "NO_ARTIFACTS"
    }
  }

  dynamic artifacts {
    for_each = var.artifacts != null ? [var.artifacts] : [] 
    content { 
      type = "S3"
      location = var.artifacts.bucket
      name = "source.zip"
      path = var.artifacts.path
      packaging = "ZIP" 
    }
  }

  cache {
    type     = "S3"
    location = var.cache_bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic environment_variable {
      for_each = var.environment_variables
      content {
        name  = environment_variable.value["name"]
        value = environment_variable.value["value"]
      }
    }
  }


  source {
    type                = "BITBUCKET"
    location            = var.repository_url
    git_clone_depth     = 1
    buildspec           = var.buildspec
    report_build_status = true

    auth {
      type     = "OAUTH"
      resource = var.auth_arn
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild[count.index].name
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "global"
  }

  lifecycle {
      # Ignore changes to role to prevent long plans
      ignore_changes = [service_role]
    }
}


resource "aws_codebuild_webhook" "webhook" {
  count = var.create == true ? 1 : 0 

  project_name = aws_codebuild_project.codebuild[count.index].name

  dynamic filter_group {
    iterator = event 
    for_each = var.event_triggers 

    content {
      filter {
        type = "EVENT"
        pattern = event.value
      }

      filter {
        type    = "HEAD_REF"
        pattern = var.branch_pattern
      }
    }
  }
  depends_on = [aws_codebuild_project.codebuild]

}

resource "aws_cloudwatch_log_group" "codebuild" {
  count = var.create == true ? 1 : 0 

  name              = "/codeBuild/${var.name}"
  retention_in_days = 3

  tags = {
    Terraform   = "true"
    Environment = "global"
  }
}
