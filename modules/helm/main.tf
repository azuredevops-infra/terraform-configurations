locals {
  # Merge helm releases with templated values
  merged_helm_releases = {
    for chart, config in var.helm_releases : chart => merge(
      config,
      {
        values = config.values_file != "" ? [
          templatefile("${path.root}/${config.values_file}", merge(
            var.template_vars,
            {
              cluster_name = var.cluster_name
              environment  = var.environment
            }
          ) )
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
  timeout          = 2000

  # Handle values from template file
  values = each.value.values_file != "" ? [
    templatefile("${path.root}/${each.value.values_file}", merge(
      var.template_vars,
      {
        cluster_name = var.cluster_name
        environment  = var.environment
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

  depends_on = [var.cluster_dependency, helm_release.nginx_ingress]
}

# Nginx Ingress Controller with Internal Load Balancer
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
          type = "LoadBalancer"
          annotations = {
            # CRITICAL: Internal Load Balancer Configuration
            "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
            "service.beta.kubernetes.io/azure-load-balancer-internal-subnet" = "${var.resource_group_name == "oorja-dev-rg" ? "oorja-dev-aks-subnet" : "aks-subnet"}"
          }
          # Remove external configurations
          externalTrafficPolicy = "Local"
          loadBalancerSourceRanges = []
        }
        # NGINX Configuration for Application Gateway integration
        config = {
          "use-forwarded-headers" = "true"
          "compute-full-forwarded-for" = "true"
          "use-proxy-protocol" = "false"
          "enable-real-ip" = "true"
          "proxy-body-size" = "0"
          "proxy-read-timeout" = "600"
          "proxy-send-timeout" = "600"
          "client-header-buffer-size" = "64k"
          "large-client-header-buffers" = "4 64k"
          "client-body-buffer-size" = "128k"
        }
        resources = var.nginx_ingress_resources
        nodeSelector = var.nginx_ingress_node_selector
        tolerations = var.nginx_ingress_tolerations
        # Ensure NGINX can handle ingress traffic properly
        ingressClassResource = {
          name = "nginx"
          enabled = true
          default = true
          controllerValue = "k8s.io/ingress-nginx"
        }

        # Add admission webhook configuration
        admissionWebhooks = {
          enabled = true
          failurePolicy = "Fail"
          port = 8443
          certificate = "/usr/local/certificates/cert"
          key = "/usr/local/certificates/key"
          namespaceSelector = {}
          objectSelector = {}
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
  count            = var.enable_opensource_prometheus || var.enable_opensource_grafana ? 1 : 0
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.monitoring_namespace
  create_namespace = true
  version          = "55.5.0"
  timeout          = 1200

  values = [
    yamlencode({
      # Grafana Configuration
      grafana = {
        enabled = var.enable_opensource_grafana
        adminPassword = var.grafana_admin_password
        
        # Proper subpath configuration
        "grafana.ini" = {
          server = {
            domain = var.grafana_domain
            root_url = "https://${var.grafana_domain}/grafana/"  # Note the trailing slash
            serve_from_sub_path = true
          }
        }
        
        service = {
          type = "ClusterIP"
          port = 80
        }
        
        persistence = {
          enabled = true
          size = var.grafana_storage_size
          storageClassName = "default"
        }
        
        resources = var.grafana_resources
        
        # Add data sources
        additionalDataSources = concat(
          var.enable_loki ? [{
            name = "Loki"
            type = "loki"
            url = "http://loki-gateway.${var.observability_namespace}.svc.cluster.local"
            access = "proxy"
          }] : [],
          var.enable_tempo ? [{
            name = "Tempo"
            type = "tempo"
            url = "http://tempo.${var.observability_namespace}.svc.cluster.local:3200"
            access = "proxy"
          }] : [],
          var.enable_mimir ? [{
            name = "Mimir"
            type = "prometheus"
            url = "http://mimir-nginx.${var.observability_namespace}.svc.cluster.local"
            access = "proxy"
          }] : []
        )
      }
      
      # Prometheus Configuration
      prometheus = {
        enabled = var.enable_opensource_prometheus
        prometheusSpec = {
          retention = var.prometheus_retention
          
          # Proper subpath configuration
          externalUrl = "https://${var.grafana_domain}/prometheus/"  # Note the trailing slash
          routePrefix = "/prometheus"
          
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
                storageClassName = "default"
              }
            }
          }
          resources = var.prometheus_resources
          
          # Remote write to Mimir if enabled
          remoteWrite = var.enable_mimir ? [{
            url = "http://mimir-nginx.${var.observability_namespace}.svc.cluster.local/api/v1/push"
            name = "mimir"
            writeRelabelConfigs = [{
              sourceLabels = ["__name__"]
              regex = "prometheus_.*"
              action = "drop"
            }]
          }] : []
        }
        
        service = {
          type = "ClusterIP"
          port = 9090
        }
      }
      
      # Alertmanager Configuration
      alertmanager = {
        enabled = var.prometheus_alertmanager_enabled
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "2Gi"
                  }
                }
                storageClassName = "default"
              }
            }
          }
          resources = var.prometheus_alertmanager_resources
          
          # Subpath configuration for alertmanager
          externalUrl = "https://${var.grafana_domain}/alertmanager/"
          routePrefix = "/alertmanager"
        }
      }
      
      # Essential components
      nodeExporter = {
        enabled = true
      }
      
      kubeStateMetrics = {
        enabled = true
      }
      
      # Disable components you don't need
      kubeEtcd = {
        enabled = false
      }
      
      kubeScheduler = {
        enabled = false
      }
      
      kubeControllerManager = {
        enabled = false
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
