resource "aws_key_pair" "yann_key" {
  key_name   = "yann-dev"
  public_key = file("keys/key.pub")

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "cluster" {
  source = "./modules/ecs-cluster"

  name            = "yann-dev"
  environment     = "dev"
  az              = var.az
  subnet_id       = data.terraform_remote_state.networking.outputs.a_pub_subnet
  security_groups = [data.terraform_remote_state.networking.outputs.api_sg_id]
  key_name        = aws_key_pair.api_prod_key.key_name
  template_dir    = var.template_dir
  instance_type   = "a1.large"
  instance_count  = 3

  enable_consul = false

  auto_scaling_group = {
    min_size         = 3
    max_size         = 6
    desired_capacity = 3
    target_groups    = values(module.api-alb.target_group_arns)
    policies = {
      up   = []
      down = []
    }
  }
  capacity_provider = true
}