## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| BITBUCKET\_TOKEN | To be removed after migrating to CodePipeline | `string` | `""` | no |
| BITBUCKET\_USER | To be removed after migrating to CodePipeline | `string` | `""` | no |
| artifacts | Artifacts bucket. Location is bucket name, path is prefix. | <pre>object({<br>    bucket = string<br>    path = string<br>  })</pre> | `null` | no |
| auth\_arn | ARN of auth resource | `string` | n/a | yes |
| branch\_pattern | Regex pattern that will trigger the build | `string` | `"^refs/heads/(master|develop)$"` | no |
| buildspec | Buildspec required for building. Default is buildspec file in root directory of the project. | `string` | `""` | no |
| cache\_bucket | Cache bucket to use for caching | `string` | n/a | yes |
| create | n/a | `bool` | `true` | no |
| environment\_variables | Environment variables | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| event\_triggers | Events that should trigger the CodeBuild project. Possible values are: PUSH, PULL\_REQUEST\_CREATED, PULL\_REQUEST\_UPDATED, PULL\_REQUEST\_REOPENED, PULL\_REQUEST\_MERGED | `list(string)` | <pre>[<br>  "PUSH"<br>]</pre> | no |
| image | Optional image. Defaults to aws/codebuild/amazonlinux2-x86\_64-standard:2.0 | `string` | `"aws/codebuild/amazonlinux2-x86_64-standard:2.0"` | no |
| name | Name of the code build project | `string` | n/a | yes |
| repository\_url | URL of the bitbucket repository | `string` | n/a | yes |
| service\_role | Name of service role | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| name | n/a |

