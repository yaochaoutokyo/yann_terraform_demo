data "terraform_remote_state" "iam" {
  backend = "remote"

  config = {
    organization = "win-techno"
    workspaces = {
      name = "satomoto-iam"
    }
  }
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

locals {
  environment_variables = concat(
  [
    {
      name  = "CONFIG_CENTER_DOMAIN"
      value = "general.prod.satomoto.com:8000"
    },
    {
      name  = "ELASTIC_APM_SERVER_URLS"
      value = "http://elasticsearch.prod.satomoto.com:8200"
    },
    {
      name  = "ELASTIC_APM_SERVER_URL"
      value = "http://elasticsearch.prod.satomoto.com:8200"
    },
    {
      name  = "ELASTIC_APM_ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "ELASTIC_APM_SERVICE_NAME"
      value = var.name
    },
    {
      name = "LOGSTASH_FIELDS"
      value = "cluster=${var.cluster_name},service=${var.name},environment=${var.environment},ecs=true"
    }
  ], 
  flatten([
    # Add health checks for consul 
    # If port is 9090, add gRPC health check instead of HTTP health check
    # Use nested list for Terraform to work
    for port in var.container_port_mappings[*].hostPort: 
      [{
        name = tostring(port) == "9090" ? "SERVICE_${port}_CHECK_GRPC" : "SERVICE_${port}_CHECK_HTTP" 
        value = tostring(port) == "9090" ? "true" : "/health"
      }, 
      {
        name = "SERVICE_${port}_CHECK_INTERVAL"
        value = "5s"
      }]
  ])
  )
}
# Task definition
resource "aws_ecs_task_definition" "task_def" {
  family             = "${var.name}-${var.environment}"
  execution_role_arn = var.execution_role_arn

  network_mode = var.network_mode
  container_definitions = templatefile(
    "${var.template_dir}/container-definitions.json",
    {
      name = var.name
      # If tag provided -> Use tag
      # Else: PROD environment -> master, GLOBAL environment -> master, DEV environment -> develop
      image = length(regexall(".*:{1}.*", var.container_image)) > 0 ? var.container_image : var.environment == "dev" ? "${var.container_image}:develop" : "${var.container_image}:master"
      # awkward null workaround
      cpu               = var.container_cpu == null ? format("%v", var.container_cpu) : jsonencode(var.container_cpu)
      cpuReservation    = var.container_cpu_soft == null ? format("%v", var.container_cpu_soft) : jsonencode(var.container_cpu_soft)
      memory            = var.container_memory == null ? format("%v", var.container_memory) : jsonencode(var.container_memory)
      memoryReservation = var.container_memory_soft == null ? format("%v", var.container_memory_soft) : jsonencode(var.container_memory_soft)
      command           = jsonencode(var.container_command)
      region            = "ap-northeast-1"
      port_mappings     = jsonencode(var.container_port_mappings)
      environment       = jsonencode(concat(var.container_environment, local.environment_variables))
      secrets           = jsonencode(var.container_secrets)
      mount_points      = jsonencode(var.container_mount_points)
      privileged        = var.container_privileged
      ulimits           = jsonencode(var.container_ulimits)
      essential         = jsonencode(true)
      volumesFrom       = jsonencode([])
      dnsServers        = jsonencode(var.container_dns_servers)
    }
  )

  dynamic "volume" {
    for_each = var.volume == null ? [] : var.volume

    content {
      name      = lookup(volume.value, "name", null)
      host_path = lookup(volume.value, "host_path", null)
    }
  }

  dynamic "volume" {
    for_each = var.docker_volume_configuration == null ? [] : [var.docker_volume_configuration]

    content {
      name = lookup(volume.value, "name", null)
      docker_volume_configuration {
        scope         = lookup(volume.value, "scope", null)
        autoprovision = lookup(volume.value, "autoprovision", null)
        driver        = lookup(volume.value, "driver", null)
        driver_opts   = lookup(volume.value, "driver_opts", null)
        labels        = lookup(volume.value, "labels", null)
      }
    }
  }


  tags = {
    Terraform   = "true"
    environment = var.environment
  }
}

data "aws_ecs_task_definition" "task_def" {
  task_definition = aws_ecs_task_definition.task_def.family

  depends_on = [aws_ecs_task_definition.task_def]
}

## Because lifecycle blocks can not be defined dynamically, two aws_ecs_service resources are specified.
## regular_service: Regular deployments
## bluegreen_service: Blue Green (CodeDeploy) deployments
## It is necessary to specifiy two services, since blue green deployments have to ignore changes in the task definition. Updating the task definition of a blue-green deployed service will cause an AWS API error.


# SERVICE FOR REGULAR SERVICES
resource "aws_ecs_service" "regular_service" {
  count = var.blue_green_deployment != null ? 0 : 1

  name            = var.name
  cluster         = var.cluster_name
  task_definition = "${aws_ecs_task_definition.task_def.family}:${max("${aws_ecs_task_definition.task_def.revision}", "${data.aws_ecs_task_definition.task_def.revision}")}"
  iam_role        = var.network_mode == "awsvpc" ? null : var.iam_role
  # Due to auto scaling, desired count has to be updated through AWS Console
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.minimum_healthy
  deployment_maximum_percent         = var.maximum_healthy

  dynamic ordered_placement_strategy {
    for_each = var.placement_strategy == null ? [] : [var.placement_strategy]

    content {
      type  = var.placement_strategy.type
      field = var.placement_strategy.field
    }
  }

  dynamic network_configuration {
    for_each = var.network_mode == "awsvpc" ? [var.network_mode] : []
    content {
      subnets         = var.network_configuration.subnet_ids
      security_groups = var.network_configuration.security_groups
    }
  }
  dynamic load_balancer {
    for_each = var.load_balancer == null ? [] : [var.load_balancer]
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = var.name
      container_port   = load_balancer.value.container_port
    }
  }
 
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [desired_count, capacity_provider_strategy]
  }
}

# SERVICE FOR BLUE GREEN SERVICES
resource "aws_ecs_service" "bluegreen_service" {
  count = var.blue_green_deployment != null ? 1 : 0

  name            = var.name
  cluster         = var.cluster_name
  task_definition = "${aws_ecs_task_definition.task_def.family}:${max("${aws_ecs_task_definition.task_def.revision}", "${data.aws_ecs_task_definition.task_def.revision}")}"
  iam_role        = var.network_mode == "awsvpc" ? null : var.iam_role
  # Due to auto scaling, desired count has to be updated through AWS Console
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.minimum_healthy
  deployment_maximum_percent         = var.maximum_healthy
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  dynamic ordered_placement_strategy {
    for_each = var.placement_strategy == null ? [] : [var.placement_strategy]

    content {
      type  = var.placement_strategy.type
      field = var.placement_strategy.field
    }
  }

  dynamic network_configuration {
    for_each = var.network_mode == "awsvpc" ? [var.network_mode] : []
    content {
      subnets         = var.network_configuration.subnet_ids
      security_groups = var.network_configuration.security_groups
    }
  }
  dynamic load_balancer {
    for_each = var.load_balancer == null ? [] : [var.load_balancer]
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = var.name
      container_port   = load_balancer.value.container_port
    }
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  # Need to manually change task definitions
  # Automatically changing is not possible due to CodeDeploy errors from the AWS API
  lifecycle {
    ignore_changes = [task_definition, load_balancer, desired_count, capacity_provider_strategy]
  }
}


resource "aws_appautoscaling_target" "ecs_target" {
  count = var.auto_scaling != null ? 1 : 0

  max_capacity       = var.auto_scaling.max_capacity
  min_capacity       = var.auto_scaling.min_capacity
  resource_id        = var.blue_green_deployment != null ? "service/${var.cluster_name}/${aws_ecs_service.bluegreen_service[count.index].name}" : "service/${var.cluster_name}/${aws_ecs_service.regular_service[count.index].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.regular_service, aws_ecs_service.bluegreen_service]
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  count              = var.auto_scaling != null ? 1 : 0
  name               = "${var.name}-${var.environment}-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.auto_scaling.metric == "CPU" ? "ECSServiceAverageCPUUtilization" : (var.auto_scaling.metric == "ALB" ? "ALBRequestCountPerTarget" : (var.auto_scaling.metric == "MEM" ? "ECSServiceAverageMemoryUtilization" : "INVALID INPUT"))
    }

    target_value       = var.auto_scaling.target_value
    scale_in_cooldown  = var.auto_scaling.scale_in_cooldown
    scale_out_cooldown = var.auto_scaling.scale_out_cooldown
  }

  depends_on = [aws_ecs_service.regular_service, aws_ecs_service.bluegreen_service]
}




# CodeDeploy app for CodeDeploy blue-green deployments
resource "aws_codedeploy_app" "deploy" {
  # Only provision this resource for CODE_DEPLOY
  count = var.blue_green_deployment != null ? 1 : 0

  compute_platform = "ECS"
  name             = "${var.cluster_name}_${var.name}"
}


resource "aws_codedeploy_deployment_group" "deploy" {
  # Only privision this resource for CODE_DEPLOY
  count = var.blue_green_deployment != null ? 1 : 0

  app_name               = aws_codedeploy_app.deploy[count.index].name
  deployment_group_name  = var.name
  service_role_arn       = data.terraform_remote_state.iam.outputs.code_deploy_role_arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 2
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = var.blue_green_deployment.lb_listener_arns
      }

      target_group {
        name = "${var.blue_green_deployment.target_name}-green-${var.environment}"
      }

      target_group {
        name = "${var.blue_green_deployment.target_name}-blue-${var.environment}"
      }
    }
  }

  depends_on = [
    aws_ecs_service.bluegreen_service[0]
  ]
}


