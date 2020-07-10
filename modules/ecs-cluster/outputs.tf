output "cluster_name" {
  value       = aws_ecs_cluster.cluster.name
  description = "Name of cluster"
}

output "cluster_arn" {
  value = aws_ecs_cluster.cluster.arn 
  description = "ARN of cluster"
}

output "instance_ids" {
  value = aws_instance.ec2_instance[*].id
}

output "instance_arns" {
  value = aws_instance.ec2_instance[*].arn
}

output "subnet_ids" {
  value = [var.subnet_id]
}

output "security_groups" {
  value = var.security_groups
}

output "public_dns" {
  value = aws_instance.ec2_instance[*].public_dns
}

output "private_dns" {
  value = aws_instance.ec2_instance[*].private_dns
}

output "public_ip" {
  value = aws_instance.ec2_instance[*].public_ip
}

output "private_ip" {
  value = aws_instance.ec2_instance[*].private_ip
}

output "primary_network_interface_ids" {
  value = aws_instance.ec2_instance[*].primary_network_interface_id
}

output "eip_public_ip" {
  value = aws_eip.eip[*].public_ip
}

output "auto_scaling_group_arn" {
  value = length(aws_autoscaling_group.main) == 1 ? aws_autoscaling_group.main[0].arn : null
}