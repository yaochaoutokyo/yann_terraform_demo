## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| template | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami | AMI to use. If not specified, use latest ecs optimized AMI for instance type. | `string` | `null` | no |
| auto\_scaling\_group | Configuration for auto scaling group. If not provided, no auto scaling group will be created. If set, auto scaling group will be created instead of regular EC2 instances. Supported metrics are: MEM, CPU, ALB. If ecs\_managed is true, no policies and alarms will be created. | <pre>object({<br>    desired_capacity = number<br>    min_size         = number<br>    max_size         = number<br>    target_groups    = list(string)<br>    policies = object({<br>      up = list(object({<br>        metric    = string<br>        threshold = number<br>        cooldown  = number<br>      }))<br>      down = list(object({<br>        metric    = string<br>        threshold = number<br>        cooldown  = number<br>      }))<br>    })<br>  })</pre> | `null` | no |
| az | Availability zone | `string` | n/a | yes |
| capacity\_provider | Whether to use a custom capacity provider or EC2. Custom capacity provider will scale auto scaling groups. | `bool` | `false` | no |
| capacity\_target | Target for resource reservations. Default is 100 | `number` | `100` | no |
| ebs\_optimized | Whether instance should be ebs optimized | `bool` | `false` | no |
| ebs\_volumes | Optional list of EBS volumes to be mounted. Either snapshot\_id or size / type have to be specified for each. snapshot\_id has priority if both are specified. Input parameters: device\_name: string / mount\_dir: string snapshot\_id: string / size: number / type: string | `list(map(any))` | `null` | no |
| efs\_dir | If provided, an Elastic File System resource will be created and all instances will mount the EFS on the provided directory | `string` | `""` | no |
| eip | Whether to add an EIP to the instance | `bool` | `false` | no |
| enable\_consul | Whether or not to run consul agents on the host instances | `bool` | `false` | no |
| environment | Environment of resources | `string` | n/a | yes |
| instance\_count | Integer for instance\_count | `any` | n/a | yes |
| instance\_profile | IAM instance profile to assume on EC2 instances | `string` | `null` | no |
| instance\_type | Instance type to use | `string` | n/a | yes |
| ipv6\_address\_count | How many IPv6 addresses to assign to the instances of the cluster | `number` | `1` | no |
| key\_name | Name of ssh key | `string` | n/a | yes |
| lifecycle\_policy | List of lifecycle policies for snapshots created for the volume. Rule is map with possible keys: cron\_expression (string), interval (string), times (comma separated list as string), count (string). https://docs.aws.amazon.com/dlm/latest/APIReference/API_CreateLifecyclePolicy.html | <pre>list(object({<br>    name = string<br>    rule = map(string)<br>  }))</pre> | `[]` | no |
| name | name | `string` | n/a | yes |
| security\_groups | List of security groups | `list(string)` | n/a | yes |
| subnet\_id | ID of subnet | `string` | n/a | yes |
| tags | Optional map of tags to add to the instances | `map(any)` | `{}` | no |
| template\_dir | Path to template dir | `any` | n/a | yes |
| user\_data\_extra | Extra command to be appended to user data | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| auto\_scaling\_group\_arn | n/a |
| cluster\_arn | ARN of cluster |
| cluster\_name | Name of cluster |
| eip\_public\_ip | n/a |
| instance\_arns | n/a |
| instance\_ids | n/a |
| primary\_network\_interface\_ids | n/a |
| private\_dns | n/a |
| private\_ip | n/a |
| public\_dns | n/a |
| public\_ip | n/a |
| security\_groups | n/a |
| subnet\_ids | n/a |

