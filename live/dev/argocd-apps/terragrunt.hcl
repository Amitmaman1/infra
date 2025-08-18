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

  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.1"
  namespace  = "argocd"

  values = [{ 
    applications = [
      {
        name: "my-app-dev",
        namespace: "argocd",
        project: "default",
        source: {
          repoURL: "https://github.com/your-org/gitops.git",
          targetRevision: "main",
          path: "helm-charts/my-app",
          helm: { valueFiles: ["values-dev.yaml"] }
        },
        destination: { server: "https://kubernetes.default.svc", namespace: "dev" },
        syncPolicy: { automated: { prune: true, selfHeal: true } }
      },
      {
        name: "my-app-staging",
        namespace: "argocd",
        project: "default",
        source: {
          repoURL: "https://github.com/your-org/gitops.git",
          targetRevision: "main",
          path: "helm-charts/my-app",
          helm: { valueFiles: ["values-staging.yaml"] }
        },
        destination: { server: "https://kubernetes.default.svc", namespace: "staging" },
        syncPolicy: { automated: { prune: true, selfHeal: true } }
      },
      {
        name: "my-app-prod",
        namespace: "argocd",
        project: "default",
        source: {
          repoURL: "https://github.com/your-org/gitops.git",
          targetRevision: "main",
          path: "helm-charts/my-app",
          helm: { valueFiles: ["values-prod.yaml"] }
        },
        destination: { server: "https://kubernetes.default.svc", namespace: "prod" },
        syncPolicy: { automated: { prune: true, selfHeal: true } }
      },
      {
        name: "edge-alb-dev",
        namespace: "argocd",
        project: "default",
        source: {
          repoURL: "https://github.com/your-org/gitops.git",
          targetRevision: "main",
          path: "helm-charts/edge-alb",
          helm: { valueFiles: ["values-dev.yaml"] }
        },
        destination: { server: "https://kubernetes.default.svc", namespace: "ingress-nginx" },
        syncPolicy: { automated: { prune: true, selfHeal: true } }
      },
      {
        name: "edge-alb-prod",
        namespace: "argocd",
        project: "default",
        source: {
          repoURL: "https://github.com/your-org/gitops.git",
          targetRevision: "main",
          path: "helm-charts/edge-alb",
          helm: { valueFiles: ["values-prod.yaml"] }
        },
        destination: { server: "https://kubernetes.default.svc", namespace: "ingress-nginx" },
        syncPolicy: { automated: { prune: true, selfHeal: true } }
      }
    ]
  }]
}
