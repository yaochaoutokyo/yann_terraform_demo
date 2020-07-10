module "back" {
  source = "./modules/ecr"
  name   = "backend"
}

module "front" {
  source = "./modules/ecr"
  name   = "frontend"
}