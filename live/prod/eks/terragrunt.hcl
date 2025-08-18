terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/eks/aws?version=20.31.1"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  cluster_name    = "prod-eks"
  cluster_version = "1.29"
  vpc_id          = dependency.vpc.outputs.vpc_id
  subnet_ids      = dependency.vpc.outputs.private_subnets

  eks_managed_node_groups = {
    general = {
      instance_types = ["t3a.large"]
      desired_size   = 2
      max_size       = 6
      min_size       = 2
    }
  }
}
