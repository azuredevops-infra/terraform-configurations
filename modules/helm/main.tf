locals {
  # Merge helm releases with templated values
  merged_helm_releases = {
    for chart, config in var.helm_releases : chart => merge(
      config,
      {
        values = config.values_file != "" ? [
          templatefile(config.values_file,
            {
              cluster_name = var.cluster_name
              environment  = var.environment
            }
          )
        ] : config.values != null ? config.values : []
      }
    )
  }
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.0"
    }
  }
}


resource "helm_release" "dynamic_releases" {
  for_each = local.merged_helm_releases

  name             = each.key
  repository       = each.value.repository
  chart            = each.value.chart
  version          = each.value.version
  namespace        = each.value.namespace
  create_namespace = each.value.create_namespace
  timeout          = 600

  # Handle values from template file
  values = each.value.values_file != "" ? [
    templatefile("${path.root}/${each.value.values_file}", merge(
      var.template_vars,
      {
        cluster_name = var.cluster_name
        environment  = var.environment
        domain_name  = "azuredev.com"  # You can make this a variable
      }
    ))
  ] : each.value.values

  # Handle individual set values
  dynamic "set" {
    for_each = each.value.sets
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [var.cluster_dependency]
}
# Nginx Ingress Controller
resource "helm_release" "nginx_ingress" {
  count            = var.enable_nginx_ingress ? 1 : 0
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = var.ingress_namespace
  create_namespace = true
  version          = var.nginx_ingress_version
  timeout          = 600

  values = [
    yamlencode({
      controller = {
        replicaCount = var.nginx_ingress_replica_count
        service = {
          type = var.nginx_ingress_service_type
          annotations = var.nginx_ingress_service_annotations
        }
        resources = var.nginx_ingress_resources
        nodeSelector = var.nginx_ingress_node_selector
        tolerations = var.nginx_ingress_tolerations
        config = {
          "use-forwarded-headers" = "true"
          "compute-full-forwarded-for" = "true"
        }
      }
      defaultBackend = {
        enabled = var.nginx_ingress_default_backend_enabled
      }
    })
  ]

  depends_on = [var.cluster_dependency]
}

# Cert-Manager for SSL certificates
resource "helm_release" "cert_manager" {
  count            = var.enable_cert_manager ? 1 : 0
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = var.cert_manager_namespace
  create_namespace = true
  version          = var.cert_manager_version
  timeout          = 600

  values = [
    yamlencode({
      installCRDs = true
      global = {
        rbac = {
          create = true
        }
      }
      resources = var.cert_manager_resources
      nodeSelector = var.cert_manager_node_selector
      tolerations = var.cert_manager_tolerations
    })
  ]

  depends_on = [var.cluster_dependency]
}

# External DNS for automatic DNS management
resource "helm_release" "external_dns" {
  count            = var.enable_external_dns ? 1 : 0
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  namespace        = var.external_dns_namespace
  create_namespace = true
  version          = var.external_dns_version
  timeout          = 600

  values = [
    yamlencode({
      provider = "azure"
      azure = {
        resourceGroup = var.resource_group_name
        tenantId = var.tenant_id
        subscriptionId = var.subscription_id
        aadClientId = var.external_dns_client_id
        aadClientSecret = var.external_dns_client_secret
      }
      sources = ["service", "ingress"]
      domainFilters = var.external_dns_domain_filters
      policy = "sync"
      resources = var.external_dns_resources
      nodeSelector = var.external_dns_node_selector
      tolerations = var.external_dns_tolerations
    })
  ]

  depends_on = [var.cluster_dependency]
}

# Prometheus monitoring stack
resource "helm_release" "kube_prometheus_stack" {
  count            = var.enable_prometheus_stack ? 1 : 0
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.monitoring_namespace
  create_namespace = true
  version          = var.prometheus_stack_version
  timeout          = 600

  values = [
    yamlencode({
      grafana = {
        enabled = var.prometheus_grafana_enabled
        service = {
          type = var.prometheus_grafana_service_type
        }
        adminPassword = var.prometheus_grafana_admin_password
        persistence = {
          enabled = var.prometheus_grafana_persistence_enabled
          size = var.prometheus_grafana_persistence_size
        }
        resources = var.prometheus_grafana_resources
      }
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
          resources = var.prometheus_resources
        }
      }
      alertmanager = {
        enabled = var.prometheus_alertmanager_enabled
        alertmanagerSpec = {
          resources = var.prometheus_alertmanager_resources
        }
      }
    })
  ]

  depends_on = [var.cluster_dependency]
}

# ArgoCD for GitOps
resource "helm_release" "argocd" {
  count            = var.enable_argocd ? 1 : 0
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.argocd_namespace
  create_namespace = true
  version          = var.argocd_version
  timeout          = 600

  values = [
    yamlencode({
      global = {
        image = {
          tag = var.argocd_image_tag
        }
      }
      server = {
        service = {
          type = var.argocd_server_service_type
        }
        ingress = {
          enabled = var.argocd_server_ingress_enabled
          annotations = var.argocd_server_ingress_annotations
          hosts = var.argocd_server_ingress_hosts
          tls = var.argocd_server_ingress_tls
        }
        resources = var.argocd_server_resources
      }
      controller = {
        resources = var.argocd_controller_resources
      }
      repoServer = {
        resources = var.argocd_repo_server_resources
      }
      dex = {
        enabled = var.argocd_dex_enabled
      }
    })
  ]

  depends_on = [var.cluster_dependency]
}

# Velero for backup (if not using the separate backup module)
resource "helm_release" "velero" {
  count            = var.enable_velero ? 1 : 0
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  namespace        = var.velero_namespace
  create_namespace = true
  version          = var.velero_version
  timeout          = 600

  values = [
    yamlencode({
      configuration = {
        provider = "azure"
        backupStorageLocation = {
          name = "default"
          provider = "azure"
          bucket = var.velero_storage_container
          config = {
            resourceGroup = var.resource_group_name
            storageAccount = var.velero_storage_account
            subscriptionId = var.subscription_id
          }
        }
        volumeSnapshotLocation = {
          name = "default"
          provider = "azure"
          config = {
            resourceGroup = var.resource_group_name
            subscriptionId = var.subscription_id
          }
        }
      }
      serviceAccount = {
        server = {
          create = true
          annotations = {
            "azure.workload.identity/client-id" = var.velero_client_id
          }
          labels = {
            "azure.workload.identity/use" = "true"
          }
        }
      }
      credentials = {
        useSecret = false
      }
      schedules = var.velero_schedules
      resources = var.velero_resources
    })
  ]

  depends_on = [var.cluster_dependency]
}

# Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  count            = var.enable_cluster_autoscaler ? 1 : 0
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  namespace        = var.cluster_autoscaler_namespace
  create_namespace = true
  version          = var.cluster_autoscaler_version
  timeout          = 600

  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = var.cluster_name
      }
      azureCloudProvider = {
        subscriptionID = var.subscription_id
        resourceGroup = var.node_resource_group
        tenantID = var.tenant_id
        clientID = var.cluster_autoscaler_client_id
      }
      extraArgs = {
        logtostderr = true
        stderrthreshold = "info"
        v = 4
        "cluster-name" = var.cluster_name
        "balance-similar-node-groups" = false
        "expander" = "random"
        "node-group-auto-discovery" = "asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}"
        "scale-down-enabled" = true
        "scale-down-delay-after-add" = "15m"
        "scale-down-unneeded-time" = "20m"
      }
      resources = var.cluster_autoscaler_resources
      nodeSelector = var.cluster_autoscaler_node_selector
      tolerations = var.cluster_autoscaler_tolerations
    })
  ]

  depends_on = [var.cluster_dependency]
}

# Keda for event-driven autoscaling
resource "helm_release" "keda" {
  count            = var.enable_keda ? 1 : 0
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = var.keda_namespace
  create_namespace = true
  version          = var.keda_version
  timeout          = 600

  values = [
    yamlencode({
      image = {
        keda = {
          tag = var.keda_image_tag
        }
        metricsApiServer = {
          tag = var.keda_metrics_server_image_tag
        }
      }
      resources = {
        operator = var.keda_operator_resources
        metricServer = var.keda_metric_server_resources
      }
      nodeSelector = var.keda_node_selector
      tolerations = var.keda_tolerations
    })
  ]

  depends_on = [var.cluster_dependency]
}

# Azure Key Vault CSI Driver
resource "helm_release" "azure_key_vault_csi" {
  count            = var.enable_azure_key_vault_csi ? 1 : 0
  name             = "csi-secrets-store-provider-azure"
  repository       = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart            = "csi-secrets-store-provider-azure"
  namespace        = var.azure_key_vault_csi_namespace
  create_namespace = true
  version          = var.azure_key_vault_csi_version
  timeout          = 600

  values = [
    yamlencode({
      secrets-store-csi-driver = {
        install = true
        linux = {
          enabled = true
          resources = var.azure_key_vault_csi_resources
        }
      }
    })
  ]

  depends_on = [var.cluster_dependency]
}