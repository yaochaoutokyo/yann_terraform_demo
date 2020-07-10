
# EC2 Instance
resource "aws_instance" "ec2_instance" {
  count = var.auto_scaling_group == null ? var.instance_count : 0

  ami                         = local.ami
  iam_instance_profile        = local.instance_profile
  vpc_security_group_ids      = var.security_groups
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  instance_type = var.instance_type
  key_name      = var.key_name
  monitoring    = false
  ebs_optimized = var.ebs_optimized
  user_data     = data.template_cloudinit_config.config.rendered
  ipv6_address_count = var.ipv6_address_count
  
  tags = merge({
    Name        = local.name
    Terraform   = "true"
    Environment = var.environment
    Cluster     = local.name
  }, var.tags)

  lifecycle {
    ignore_changes = [ami, user_data, tags]
  }
}

resource "aws_eip" "eip" {
  count = var.eip == true && var.auto_scaling_group == null ? var.instance_count : 0

  instance          = aws_instance.ec2_instance[count.index].id
  network_interface = aws_instance.ec2_instance[count.index].primary_network_interface_id
  vpc               = true

  tags = {
    Name        = aws_instance.ec2_instance[count.index].tags.Name
    Terraform   = true
    Environment = var.environment
  }
}

resource "aws_route53_record" "A" {
  count = var.auto_scaling_group == null ? 1 : 0
  zone_id = local.zone_id
  name    = local.record_name
  ttl     = "300"
  type    = "A"
  records = aws_instance.ec2_instance[*].private_ip
  allow_overwrite = true

  lifecycle {
    ignore_changes = [records]
  }
}