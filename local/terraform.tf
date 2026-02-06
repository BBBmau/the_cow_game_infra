# Local infra stack – runs against your current kubeconfig (minikube, kind, Docker Desktop, etc.)
# No GCP resources; use this to debug how the cow game infra is managed.

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path != "" ? var.kubeconfig_path : null
  # When config_path is null, provider uses KUBECONFIG env or ~/.kube/config
}
