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
| blue\_green | Whether to support blue/green deplyments by creating blue/green target groups | `bool` | n/a | yes |
| environment | Environment. Either DEV or PROD. | `string` | n/a | yes |
| idle\_timeout | Connection idle timeout (second) | `number` | `60` | no |
| internal | Whether to create an intranet or internet facing ALB | `bool` | `true` | no |
| security\_groups | List of security group IDs | `list(string)` | n/a | yes |
| subnets | List of subnet IDs | `list(string)` | n/a | yes |
| targets | The targets. Name is name of target group, health\_check is path to health check on. address is condition for target group in listener. | <pre>list(object({<br>    name         = string<br>    health_check = string<br>    address      = string<br>  }))</pre> | n/a | yes |
| type | Target group registration type. Default is instance | `string` | `"instance"` | no |
| vpc | ID of VPC to run ALB in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| listener\_arns | n/a |
| target\_group\_arns | Returns a map of target group arns with key=name, value=arn |

