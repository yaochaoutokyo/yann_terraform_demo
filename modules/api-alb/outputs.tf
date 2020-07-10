output "listener_arns" {
  value = [aws_lb_listener.api-listener.arn]
}

output "target_group_arns" {
  value       = zipmap(aws_lb_target_group.tg[*].name, aws_lb_target_group.tg[*].arn)
  description = "Returns a map of target group arns with key=name, value=arn"
}

