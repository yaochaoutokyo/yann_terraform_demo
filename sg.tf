resource "aws_security_group" "front_alb" {
  name_prefix = "front-alb-dev-"
  description = "Security group for front ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    description      = "anywhere"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    description      = "anywhere"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "allow all"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "front_instance" {
  name_prefix = "front-dev-"
  description = "Security group for frontend instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 49153
    to_port         = 65535
    protocol        = "tcp"
    description     = "allow dynamic port mappings for ALB"
    self            = true
    security_groups = [aws_security_group.front_alb.id]
  }

  ingress {
    from_port       = 32768
    to_port         = 61000
    protocol        = "tcp"
    description     = "allow dynamic port mappings for ALB"
    self            = true
    security_groups = [aws_security_group.front_alb.id]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "allow all in api-sg"
    self        = true
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "allow front load balancer"
    security_groups = [aws_security_group.front_alb.id]
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "allow all"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


resource "aws_security_group" "back_alb" {
  name_prefix = "back-alb-dev-"
  description = "Security group for backend ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    description      = "allow front instances"
    security_groups = [aws_security_group.front_instance.id]
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "allow all"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "back_instance" {
  name_prefix = "back-dev-"
  description = "Security group for backend instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 49153
    to_port         = 65535
    protocol        = "tcp"
    description     = "allow dynamic port mappings for ALB"
    self            = true
    security_groups = [aws_security_group.back_alb.id]
  }

  ingress {
    from_port       = 32768
    to_port         = 61000
    protocol        = "tcp"
    description     = "allow dynamic port mappings for ALB"
    self            = true
    security_groups = [aws_security_group.back_alb.id]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "allow all in back-instance-sg"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "allow all"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}