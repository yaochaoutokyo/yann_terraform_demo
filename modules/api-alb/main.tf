locals {
  blue_green = ["green", "blue"]
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

data "terraform_remote_state" "general" {
  backend = "remote"

  config = {
    organization = "win-techno"
    workspaces = {
      name = "satomoto-general"
    }
  }
}


resource "aws_lb" "api-alb" {
  name               = "api-${var.environment}"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets
  idle_timeout       = var.idle_timeout
  access_logs {
    bucket  = data.terraform_remote_state.general.outputs.log_bucket
    prefix  = "api-lb-${var.environment}"
    enabled = true
  }

}


resource "aws_route53_record" "dns" {
  zone_id = var.environment == "dev" ? data.terraform_remote_state.networking.outputs.dev_private_dns_hosted_zone_id : data.terraform_remote_state.networking.outputs.prod_private_dns_hosted_zone_id
  name    = "api-lb.${var.environment}.satomoto.com"
  type    = "A"
  alias {
    name                   = "dualstack.${aws_lb.api-alb.dns_name}"
    zone_id                = aws_lb.api-alb.zone_id
    evaluate_target_health = false
  }
  allow_overwrite = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "api-listener" {
  load_balancer_arn = aws_lb.api-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }

  depends_on = [
    aws_lb.api-alb,
    aws_lb_target_group.tg[0],
  ]
  lifecycle {
    ignore_changes = [
      default_action[0].target_group_arn,
    ]
  }
}

resource "aws_lb_listener_rule" "rule" {
  count = length(var.targets)

  listener_arn = aws_lb_listener.api-listener.arn
  priority     = count.index + 1

  action {
    type             = "forward"
    target_group_arn = try(aws_lb_target_group.tg[count.index].arn, "No target group found. This is expected during the plan.")
  }

  condition {
    path_pattern {
      values = [var.targets[count.index].address]
    }
  }

  lifecycle {
    ignore_changes = [
      action[0].target_group_arn,
    ]
  }
}

resource "aws_lb_target_group" "tg" {
  count = var.blue_green == true ? 2 * length(var.targets) : length(var.targets)

  name                 = var.blue_green == true ? count.index < length(var.targets) ? "${var.targets[count.index].name}-${local.blue_green[0]}-${var.environment}" : "${var.targets[count.index - length(var.targets)].name}-${local.blue_green[1]}-${var.environment}" : "${var.targets[count.index].name}-${var.environment}"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc
  target_type          = var.type
  deregistration_delay = 300
  slow_start           = 0


  health_check {
    enabled             = true
    interval            = 30
    path                = var.blue_green == true ? count.index < length(var.targets) ? var.targets[count.index].health_check : var.targets[count.index - length(var.targets)].health_check : var.targets[floor(count.index)].health_check
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }
  depends_on = [
    aws_lb.api-alb
  ]

  tags = {
    Terraform   = "true"
    BlueGreen   = var.blue_green == true ? count.index < length(var.targets) ? local.blue_green[0] : local.blue_green[1] : "no"
    Environment = var.environment
  }
}
