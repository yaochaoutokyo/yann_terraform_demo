# Import the most recent EBS optimized AMIs from SSM
data "aws_ssm_parameter" "ami_amd64" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_ssm_parameter" "ami_arm64" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended/image_id"
}


data "terraform_remote_state" "networking" {
  backend = "remote"

  config = {
    organization = "win-techno"
    workspaces = {
      name = "satomoto-networking"
    }
  }
}

data "terraform_remote_state" "iam" {
  backend = "remote"

  config = {
    organization = "win-techno"
    workspaces = {
      name = "satomoto-iam"
    }
  }
}

data "terraform_remote_state" "lambda" {
  backend = "remote"

  config = {
    organization = "win-techno"
    workspaces = {
      name = "satomoto-lambda-prod"
    }
  }
}

data "terraform_remote_state" "general" {
  backend = "remote"

  config = {
    organization = "win-techno"
    workspaces = {
      name = "satomoto-general"
    }
  }
}

locals {
  # Default name 
  name = "${var.name}-${var.environment}"
  # Find correct AMI for architecture type (ARM64/AMD64)
  ami = var.ami == null ? substr("${var.instance_type}", 0, 1) == "a" ? "${data.aws_ssm_parameter.ami_arm64.value}" : "${data.aws_ssm_parameter.ami_amd64.value}" : var.ami
  # Assign instance profile if provided, else use default
  instance_profile = var.instance_profile != null ? var.instance_profile : data.terraform_remote_state.iam.outputs.ecs_instance_profile
  # Hosted zone ID for dev or prod
  zone_id = var.environment == "dev" ? data.terraform_remote_state.networking.outputs.dev_private_dns_hosted_zone_id : data.terraform_remote_state.networking.outputs.prod_private_dns_hosted_zone_id
  # DNS record name for dev or prod 
  record_name = "${var.name}.${var.environment == "global" ? "prod" : var.environment}.satomoto.com"
}
# ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name = local.name

  capacity_providers = aws_ecs_capacity_provider.capacity[*].name
  dynamic default_capacity_provider_strategy {
    for_each = var.capacity_provider == false ? [] : [var.capacity_provider]

    content {
      capacity_provider = aws_ecs_capacity_provider.capacity[0].name
      weight            = 1
    }
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}


data "template_cloudinit_config" "config" {
  # Main cloud-config configuration file.
  part {
    content_type = "text/cloud-boothook"
    content      = data.template_file.boothook.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.user_data.rendered
  }

}

data "template_file" "boothook" {
  template = file("${var.template_dir}/cloud-boothook.sh")

  vars = {
    EFS_DIR = var.efs_dir 
    MOUNT_TARGET = try(aws_efs_mount_target.mount[0].dns_name, "expected error in plan")
  }
}

data "template_file" "user_data" {
  template = file("${var.template_dir}/user-data.sh")

  vars = {
    CLUSTER_NAME   = local.name
    ENVIRONMENT = var.environment
    DNS_RECORD     = local.record_name
    HOSTED_ZONE_ID = local.zone_id
    # use amd64 as default, unless arm64 instance type specified
    ARCH                  = var.ami == null ? substr("${var.instance_type}", 0, 1) == "a" ? "arm64" : "amd64" : "amd64"
    MOUNTED_DEVICES       = var.ebs_volumes != null ? length(var.ebs_volumes) > 0 ? join(", ", var.ebs_volumes[*].device_name) : "" : ""
    MOUNT_DIRS            = var.ebs_volumes != null ? length(var.ebs_volumes) > 0 ? join(", ", var.ebs_volumes[*].mount_dir) : "" : ""
    NODE_EXPORTER_VERSION = "0.18.1"
    ENABLE_CONSUL = var.enable_consul
    EXTRA_COMMAND         = var.user_data_extra
  }
}
