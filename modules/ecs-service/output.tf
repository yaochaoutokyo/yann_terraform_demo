output "deployment_application_id" {
  value = length(aws_codedeploy_app.deploy) > 0 ? aws_codedeploy_app.deploy[0].id : null
}

output "deployment_application_name" {
  value = length(aws_codedeploy_app.deploy) > 0 ? aws_codedeploy_app.deploy[0].name : null
}

output "deployment_group_id" {
  value = length(aws_codedeploy_deployment_group.deploy) > 0 ? aws_codedeploy_deployment_group.deploy[0].id : null
}
