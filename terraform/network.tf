module "network" {
  source = "./modules/network"

  name_prefix = "ec2-dnv-class"
  vpc_cidr    = "10.0.0.0/16"
  tags        = var.tags
}