# Launch Configuration + Auto Scaling Group 
resource "aws_launch_configuration" "launch" {
  count = var.auto_scaling_group == null ? 0 : 1

  name_prefix = "${var.name}-${var.environment}-"

  iam_instance_profile = local.instance_profile

  instance_type = var.instance_type
  image_id      = local.ami

  enable_monitoring = false

  key_name                    = var.key_name
  security_groups             = var.security_groups
  associate_public_ip_address = false

  user_data = data.template_file.user_data.rendered

  # No EBS volumes supported for auto scaling groups at this time. 
  # EBS volumes would get deleted when instances get removed 
  # Need to add replication layer to allow EBS volumes in auto scaling groups
}

resource "aws_autoscaling_group" "main" {
  count = var.auto_scaling_group == null ? 0 : 1

  name = local.name

  launch_configuration = aws_launch_configuration.launch[count.index].id
  termination_policies = ["OldestLaunchConfiguration", "Default"]
  vpc_zone_identifier  = [var.subnet_id]

  target_group_arns = var.auto_scaling_group.target_groups

  desired_capacity = var.auto_scaling_group.desired_capacity
  max_size         = var.auto_scaling_group.max_size
  min_size         = var.auto_scaling_group.min_size

  # Required for ECS scaling. Enable if capacity provider used.
  protect_from_scale_in = var.capacity_provider

  lifecycle {
    create_before_destroy = true
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = local.name
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
  tag {
    key                 = "Terraform"
    value               = true
    propagate_at_launch = true
  }
  tag {
    key                 = "Cluster"
    value               = local.name
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_notification" "asg_notification" {
  count = var.environment == "dev" || var.auto_scaling_group == null ? 0 : 1

  group_names = [
    aws_autoscaling_group.main[count.index].name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = data.terraform_remote_state.general.outputs.auto_scaling_sns
}


resource "aws_autoscaling_policy" "scale-up" {
  count = var.auto_scaling_group == null || var.capacity_provider == true ? 0 : length(var.auto_scaling_group.policies.up)

  name                   = "scale-up-${var.auto_scaling_group.policies.up[count.index].metric}-${count.index}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.auto_scaling_group.policies.up[count.index].cooldown
  autoscaling_group_name = aws_autoscaling_group.main[0].name
}

resource "aws_autoscaling_policy" "scale-down" {
  count                  = var.auto_scaling_group == null || var.capacity_provider == true ? 0 : length(var.auto_scaling_group.policies.down)
  name                   = "scale-down-${var.auto_scaling_group.policies.down[count.index].metric}-${count.index}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.auto_scaling_group.policies.down[count.index].cooldown
  autoscaling_group_name = aws_autoscaling_group.main[0].name
}

resource "aws_cloudwatch_metric_alarm" "high" {
  count = var.auto_scaling_group == null || var.capacity_provider == true ? 0 : length(var.auto_scaling_group.policies.up)

  alarm_name          = "${aws_autoscaling_group.main[0].name}-${var.auto_scaling_group.policies.up[count.index].metric}-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = var.auto_scaling_group.policies.up[count.index].metric == "MEM" ? "MemoryUtilization" : var.auto_scaling_group.policies.up[count.index].metric == "CPU" ? "CPUUtilization" : var.auto_scaling_group.policies.up[count.index].metric == "ALB" ? "RequestCountPerTarget" : "INVALID VALUE"
  namespace           = var.auto_scaling_group.policies.up[count.index].metric == "MEM" ? "System/Linux" : "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.auto_scaling_group.policies.up[count.index].threshold
  alarm_description   = "This metric monitors ec2 ${var.auto_scaling_group.policies.up[count.index].metric} for high utilization on hosts"
  alarm_actions = [
    aws_autoscaling_policy.scale-up[count.index].arn
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[0].name
  }
}

resource "aws_cloudwatch_metric_alarm" "low" {
  count = var.auto_scaling_group == null || var.capacity_provider == true ? 0 : length(var.auto_scaling_group.policies.down)

  alarm_name          = "${aws_autoscaling_group.main[0].name}-${var.auto_scaling_group.policies.down[count.index].metric}-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = var.auto_scaling_group.policies.down[count.index].metric == "MEM" ? "MemoryUtilization" : var.auto_scaling_group.policies.down[count.index].metric == "CPU" ? "CPUUtilization" : var.auto_scaling_group.policies.down[count.index].metric == "ALB" ? "RequestCountPerTarget" : "INVALID VALUE"
  namespace           = var.auto_scaling_group.policies.down[count.index].metric == "MEM" ? "System/Linux" : "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.auto_scaling_group.policies.down[count.index].threshold
  alarm_description   = "This metric monitors ec2 ${var.auto_scaling_group.policies.down[count.index].metric} for low utilization on hosts"
  alarm_actions = [
    aws_autoscaling_policy.scale-down[count.index].arn
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[0].name
  }
}



resource "aws_ecs_capacity_provider" "capacity" {
  count = var.capacity_provider == true ? 1 : 0

  name = "${local.name}-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.main[count.index].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = var.capacity_target
    }
  }

  lifecycle {
    // ignore changes to target capacity since API does not support updating capacity providers at this time
    ignore_changes = [auto_scaling_group_provider.0.managed_scaling.0.target_capacity]
  }
}
