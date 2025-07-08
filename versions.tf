terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.20.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.0"
    }
  }
  required_version = ">= 1.5.0"


  backend "remote" {
    organization = "oorja_terraform"
    workspaces {
      name = "aks-infra2"
    }
  }
}

provider "azurerm" {
  subscription_id = "3e336171-d512-41a4-8f0d-01790f9543e0"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "kubernetes" {
  host                   = module.aks.admin_kubeconfig.host
  client_certificate     = base64decode(module.aks.admin_kubeconfig.client_certificate)
  client_key             = base64decode(module.aks.admin_kubeconfig.client_key)
  cluster_ca_certificate = base64decode(module.aks.admin_kubeconfig.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.admin_kubeconfig.host
    client_certificate     = base64decode(module.aks.admin_kubeconfig.client_certificate)
    client_key             = base64decode(module.aks.admin_kubeconfig.client_key)
    cluster_ca_certificate = base64decode(module.aks.admin_kubeconfig.cluster_ca_certificate)
  }
}

/*
provider "kubernetes" {
  host                   = try(module.aks.host, "https://127.0.0.1")
  cluster_ca_certificate = try(base64decode(module.aks.cluster_ca_certificate), null)
  
  # Use exec for Azure AD authentication
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--environment", "AzurePublicCloud",
      "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630", # This is the AKS Azure AD server app ID
      "--client-id", "80faf920-1908-4b52-b5ef-a8e7bedfc67a", # This is the AKS Azure AD client app ID
      "--tenant-id", "2597dc73-3992-4b01-a65e-7f6e4779e9c6", # Your tenant ID from the AKS output
      "--login", "azurecli" # Use Azure CLI authentication
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = try(module.aks.host, "https://127.0.0.1")
    cluster_ca_certificate = try(base64decode(module.aks.cluster_ca_certificate), null)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token",
        "--environment", "AzurePublicCloud",
        "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630",
        "--client-id", "80faf920-1908-4b52-b5ef-a8e7bedfc67a",
        "--tenant-id", "2597dc73-3992-4b01-a65e-7f6e4779e9c6",
        "--login", "azurecli"
      ]
    }
  }
} */

data "azurerm_client_config" "current" {}