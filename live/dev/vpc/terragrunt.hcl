terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=5.5.3"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  name   = "dev-vpc"
  cidr   = "10.0.0.0/16"
  azs    = ["us-east-1a", "us-east-1b"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway       = true
  single_nat_gateway       = true
  one_nat_gateway_per_az   = false
  enable_dns_hostnames     = true
  enable_dns_support       = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}