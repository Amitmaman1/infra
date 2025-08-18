terraform {
  source  = "aigisuk/argocd/kubernetes"
  version = "1.0.6"
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
  cluster_name     = dependency.eks.outputs.cluster_name
  cluster_endpoint = dependency.eks.outputs.cluster_endpoint
  cluster_ca       = dependency.eks.outputs.cluster_certificate_authority_data
  namespace        = "argocd"
  releaseName      = "argocd"
}
