
# Create volumes if specified
resource "aws_ebs_volume" "volume" {
  count = var.ebs_volumes == null ? 0 : length(var.ebs_volumes) * var.instance_count
  # n instances, m volumes
  # instance 0 ebs_volumes[0]
  # instance 1 ebs_volumes[0]
  # ...
  # instance n ebs_volumes[0]
  # instance 0 ebs_volumes[1]
  # instance 1 ebs_volumes[1]
  # ...
  # instance n-1 ebs_volumes[1]
  # instance n-1 ebs_volumes[m-1]
  # ...
  # instance n-1 ebs_volumes[m-1]
  availability_zone = var.az
  snapshot_id       = lookup(var.ebs_volumes[floor(count.index / var.instance_count)], "snapshot_id", null)
  size = lookup(var.ebs_volumes[floor(count.index / var.instance_count)], "size", null)
  # Prioritize snapshot_id
  type = lookup(var.ebs_volumes[floor(count.index / var.instance_count)], "snapshot_id", null) == null ? lookup(var.ebs_volumes[floor(count.index / var.instance_count)], "type", null) : null

  tags = {
    // Name = (volume_name | incrementing counter)-instance_id-environment
    Name        = "${lookup(var.ebs_volumes[floor(count.index / var.instance_count)], "name", floor(count.index / var.instance_count))}-${aws_instance.ec2_instance[count.index % var.instance_count].id}-${var.environment}"
    Terraform   = "true"
    Environment = var.environment
    Instance    = aws_instance.ec2_instance[count.index % var.instance_count].id
    DeviceName = lookup(var.ebs_volumes[floor(count.index / var.instance_count)], "device_name", null)
    Cluster = local.name
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count = var.ebs_volumes == null ? 0 : length(var.ebs_volumes) * var.instance_count

  device_name = try(aws_ebs_volume.volume[count.index].tags["DeviceName"], "expected error in plan")
  volume_id   = aws_ebs_volume.volume[count.index].id
  instance_id = try(aws_ebs_volume.volume[count.index].tags["Instance"], "expected error in plan")
}

# Create snapshots for the volumes of this instance
resource "aws_dlm_lifecycle_policy" "lifecycle" {
  count = var.ebs_volumes == null ? 0 : length(var.lifecycle_policy)

  description        = "DLM lifecycle policy for cluster ${local.name}"
  execution_role_arn = data.terraform_remote_state.iam.outputs.dlm_lifecycle_role_arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = var.lifecycle_policy[count.index].name

      create_rule {
        #cron_expression = lookup(var.lifecycle_policy[count.index].rule, "cron_expression", null)
        interval      = lookup(var.lifecycle_policy[count.index].rule, "interval", null)
        # Prioritize cron_expression
        interval_unit = lookup(var.lifecycle_policy[count.index].rule, "cron_expression", null) == null ? "HOURS" : null
        # Split comma separated list
        times         = split(",",lookup(var.lifecycle_policy[count.index].rule, "times", ""))
      }

      retain_rule {
        count = var.lifecycle_policy[count.index].rule.count
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }

    target_tags = {
      Cluster = local.name
    }
  }

  lifecycle {
    # Ignore changes to schedule to allow modifications through AWS Console
    ignore_changes = [policy_details[0].schedule]
  }
}






resource "aws_efs_file_system" "efs" {
  count = var.efs_dir == "" ? 0 : 1

  tags = {
    Cluster     = local.name
    Terraform   = "true"
    Environment = var.environment
  }

  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
}

resource "aws_efs_mount_target" "mount" {
  count = var.efs_dir == "" ? 0 : 1

  file_system_id = aws_efs_file_system.efs[count.index].id
  subnet_id      = var.subnet_id
  security_groups = var.security_groups
}