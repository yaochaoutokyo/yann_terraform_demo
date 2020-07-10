## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| auto\_scaling | Configuration of auto scaling for the service. Valid values for metric are: CPU, MEM, ALB | <pre>object({<br>    max_capacity       = number<br>    min_capacity       = number<br>    metric             = string<br>    target_value       = number<br>    scale_in_cooldown  = number<br>    scale_out_cooldown = number<br>  })</pre> | `null` | no |
| blue\_green\_deployment | Optional blue green deployment configuration. target\_name is coin type as used when creating ALB. target\_name will be used for blue/green target groups. | <pre>object({<br>    target_name = string<br>    lb_listener_arns = list(string)<br>  })</pre> | `null` | no |
| cluster\_name | Name of cluster | `string` | n/a | yes |
| container\_command | List of commands, as separated by whitespace | `list(string)` | `[]` | no |
| container\_cpu | Hard CPU specification of container | `number` | `null` | no |
| container\_cpu\_soft | Soft CPU specification of container | `number` | `null` | no |
| container\_dns\_servers | List of DNS servers to pass to containers | `list(string)` | `[]` | no |
| container\_environment | Environment variables | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| container\_image | Image of the container. If a tag is specified, that tag will be used. Else, either master or develop tags will be used, based on the environment. | `string` | n/a | yes |
| container\_memory | Hard memory specification of container | `number` | `null` | no |
| container\_memory\_soft | Soft memory specification of container | `number` | `null` | no |
| container\_mount\_points | List of mount points | <pre>list(object({<br>    sourceVolume  = string<br>    containerPath = string<br>  }))</pre> | `[]` | no |
| container\_port\_mappings | List of port mappings | <pre>list(object({<br>    containerPort = number<br>    hostPort      = number<br>    protocol      = string<br>  }))</pre> | `[]` | no |
| container\_privileged | Give container privileged access | `bool` | `false` | no |
| container\_secrets | Sensitive environment variables | <pre>list(object({<br>    name      = string<br>    valueFrom = string<br>  }))</pre> | `[]` | no |
| container\_ulimits | Ulimits of taskd ef | <pre>list(object({<br>    softLimit = number <br>    hardLimit = number <br>    name = string<br>  }))</pre> | `[]` | no |
| desired\_count | Desired count for this service. Due to auto scaling, desired count has to be updated through AWS Console | `number` | `1` | no |
| docker\_volume\_configuration | Optional docker volume | <pre>object({<br>    name          = string<br>    scope         = string<br>    autoprovision = bool<br>    driver        = string<br>    driver_opts   = map(string)<br>    labels        = map(string)<br>  })</pre> | `null` | no |
| environment | environment | `string` | n/a | yes |
| execution\_role\_arn | Optional ARN of IAM role for tasks | `string` | `""` | no |
| iam\_role | Optional ARN of IAM role for the service | `string` | `null` | no |
| load\_balancer | Load balancer configuration | <pre>object({<br>    target_group_arn = string<br>    container_port   = number<br>  })</pre> | `null` | no |
| maximum\_healthy | Percentage of maximum healthy tasks | `number` | `200` | no |
| minimum\_healthy | Percentage of minimum healthy tasks | `number` | `100` | no |
| name | name | `string` | n/a | yes |
| network\_configuration | Network configuration of the service. Required if network mode is awsvpc | <pre>object({<br>    subnet_ids      = list(string)<br>    security_groups = list(string)<br>  })</pre> | `null` | no |
| network\_mode | Network mode to use for the task. Default is bridge | `string` | `"bridge"` | no |
| placement\_strategy | Placement strategy for tasks. Valid type values are: binpack, random, spread. For binpack, fields are: cpu, memory. For spread: instanceId. For random: null. | <pre>object({<br>    type  = string<br>    field = string<br>  })</pre> | `null` | no |
| template\_dir | Relative path to the template directory | `string` | n/a | yes |
| volume | Optional volume struct | <pre>list(object({<br>    name      = string<br>    host_path = string<br>  }))</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| deployment\_application\_id | n/a |
| deployment\_application\_name | n/a |
| deployment\_group\_id | n/a |

