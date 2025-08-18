terraform {
  source  = "terraform-helm/helm-release/kubernetes"
  version = "2.9.0"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "eks" {
  config_path = "../eks"
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

variable "cluster_name" {}
variable "cluster_endpoint" {}
variable "cluster_ca" {}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

EOF
}

inputs = {
  cluster_name      = dependency.eks.outputs.cluster_name
  cluster_endpoint  = dependency.eks.outputs.cluster_endpoint
  cluster_ca        = dependency.eks.outputs.cluster_certificate_authority_data

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  namespace  = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = dependency.eks.outputs.cluster_name
    },
    {
      name  = "region"
      value = "us-east-1"
    },
    {
      name  = "vpcId"
      value = dependency.eks.outputs.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }
  ]
}
