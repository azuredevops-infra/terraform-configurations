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

# Create namespace for observability stack
resource "kubernetes_namespace" "observability" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
      "app.kubernetes.io/name" = "observability-stack"
      "app.kubernetes.io/instance" = "${var.prefix}-${var.environment}"
    }
  }
}

# Create storage secret for Azure Storage
resource "kubernetes_secret" "azure_storage" {
  metadata {
    name      = "azure-storage-secret"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    azurestorageaccountname = var.storage_account_name
    azurestorageaccountkey  = var.storage_account_key
  }

  type = "Opaque"
}

# Loki for log aggregation
resource "helm_release" "loki" {
  count            = var.enable_loki ? 1 : 0
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  namespace        = kubernetes_namespace.observability.metadata[0].name
  version          = var.loki_version
  timeout          = 600
  create_namespace = false

  values = [
    yamlencode({
      deploymentMode = "SingleBinary"
      
      loki = {
        auth_enabled = false
        
        commonConfig = {
          replication_factor = 1
        }
        
        storage = {
          type = "filesystem"
        }
        
        schemaConfig = {
          configs = [
            {
              from = "2024-01-01"
              store = "tsdb"
              object_store = "filesystem"
              schema = "v13"
              index = {
                prefix = "index_"
                period = "24h"
              }
            }
          ]
        }
        
        limits_config = {
          retention_period = var.loki_retention_period
          enforce_metric_name = false
          reject_old_samples = true
          reject_old_samples_max_age = "168h"
          max_cache_freshness_per_query = "10m"
          split_queries_by_interval = "15m"
        }
        
        compactor = {
          working_directory = "/var/loki/compactor"
          shared_store = "filesystem"
          compaction_interval = "10m"
          retention_enabled = true
          retention_delete_delay = "2h"
          retention_delete_worker_count = 150
        }
      }

      singleBinary = {
        replicas = 1
        resources = var.loki_resources
        nodeSelector = var.node_selector
        tolerations = var.tolerations
        persistence = {
          enabled = true
          size = var.loki_storage_size
          storageClass = "default"
        }
      }

      gateway = {
        enabled = true
        replicas = 1
        service = {
          type = "ClusterIP"
          port = 80
        }
        ingress = {
          enabled = false
        }
      }

      monitoring = {
        dashboards = {
          enabled = true
          annotations = {
            "grafana_folder" = "Loki"
          }
        }
        rules = {
          enabled = true
          alerting = true
        }
        serviceMonitor = {
          enabled = true
        }
        selfMonitoring = {
          enabled = false
          grafanaAgent = {
            installOperator = false
          }
        }
      }

      test = {
        enabled = false
      }
    })
  ]

  depends_on = [var.cluster_dependency, kubernetes_namespace.observability]
}
# Promtail for log collection
resource "helm_release" "promtail" {
  count            = var.enable_promtail ? 1 : 0
  name             = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  namespace        = kubernetes_namespace.observability.metadata[0].name
  version          = var.promtail_version
  timeout          = 600
  create_namespace = false

  values = [
    yamlencode({
      config = {
        clients = [
          {
            url = "http://loki-gateway.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local/loki/api/v1/push"
          }
        ]
        positions = {
          filename = "/tmp/positions.yaml"
        }
        server = {
          http_listen_port = 3101
        }
        target_config = {
          sync_period = "10s"
        }
        scrape_configs = [
          {
            job_name = "kubernetes-pods"
            kubernetes_sd_configs = [
              {
                role = "pod"
              }
            ]
            pipeline_stages = [
              {
                cri = {}
              }
            ]
            relabel_configs = [
              {
                source_labels = ["__meta_kubernetes_pod_controller_name"]
                regex = "([0-9a-z-.]+?)(-[0-9a-f]{8,10})?"
                action = "replace"
                target_label = "__tmp_controller_name"
              },
              {
                source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name", "__meta_kubernetes_pod_label_app", "__tmp_controller_name", "__meta_kubernetes_pod_name"]
                regex = "^;*([^;]+)(;.*)?$"
                action = "replace"
                target_label = "app"
              },
              {
                source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_component", "__meta_kubernetes_pod_label_component"]
                regex = "^;*([^;]+)(;.*)?$"
                action = "replace"
                target_label = "component"
              }
            ]
          }
        ]
      }

      resources = {
        limits = {
          cpu = "200m"
          memory = "128Mi"
        }
        requests = {
          cpu = "100m"
          memory = "64Mi"
        }
      }

      nodeSelector = var.node_selector
      tolerations = var.tolerations

      serviceMonitor = {
        enabled = true
      }
    })
  ]

  depends_on = [helm_release.loki, kubernetes_namespace.observability]
}

# Tempo for distributed tracing
resource "helm_release" "tempo" {
  count            = var.enable_tempo ? 1 : 0
  name             = "tempo"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo"
  namespace        = kubernetes_namespace.observability.metadata[0].name
  version          = var.tempo_version
  timeout          = 600
  create_namespace = false

  values = [
    yamlencode({
      tempo = {
        repository = "grafana/tempo"
        tag = "2.3.1"
        pullPolicy = "IfNotPresent"
        
        storage = {
          trace = {
            backend = "local"
            local = {
              path = "/var/tempo/traces"
            }
          }
        }
        
        retention = var.tempo_retention_period
        
        resources = var.tempo_resources
        nodeSelector = var.node_selector
        tolerations = var.tolerations
        
        persistence = {
          enabled = true
          size = var.tempo_storage_size
          storageClassName = "default"
        }
      }

      serviceMonitor = {
        enabled = true
      }

      service = {
        type = "ClusterIP"
      }
    })
  ]

  depends_on = [var.cluster_dependency, kubernetes_namespace.observability]
}

# Mimir for long-term metrics storage
resource "helm_release" "mimir" {
  count            = var.enable_mimir ? 1 : 0
  name             = "mimir"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "mimir-distributed"
  namespace        = kubernetes_namespace.observability.metadata[0].name
  version          = var.mimir_version
  timeout          = 900
  create_namespace = false

  values = [
    yamlencode({
      mimir = {
        config = {
          common = {
            storage = {
              backend = "filesystem"
              filesystem = {
                dir = "/data"
              }
            }
          }
          
          blocks_storage = {
            backend = "filesystem"
            filesystem = {
              dir = "/data/blocks"
            }
          }
          
          alertmanager_storage = {
            backend = "filesystem"
            filesystem = {
              dir = "/data/alertmanager"
            }
          }
          
          ruler_storage = {
            backend = "filesystem"
            filesystem = {
              dir = "/data/ruler"
            }
          }
          
          limits = {
            compactor_blocks_retention_period = var.mimir_retention_period
          }
          
          auth_enabled = false
          
          server = {
            http_listen_port = 8080
            grpc_listen_port = 9095
          }
          
          memberlist = {
            join_members = ["mimir-memberlist"]
          }
        }
      }

      # Component configurations
      ingester = {
        replicas = 1
        resources = var.mimir_resources
        nodeSelector = var.node_selector
        tolerations = var.tolerations
        persistence = {
          enabled = true
          size = var.mimir_storage_size
        }
      }

      distributor = {
        replicas = 1
        resources = {
          requests = {
            cpu = "500m"
            memory = "512Mi"
          }
          limits = {
            cpu = "1000m"
            memory = "1Gi"
          }
        }
        nodeSelector = var.node_selector
        tolerations = var.tolerations
      }

      querier = {
        replicas = 1
        resources = var.mimir_resources
        nodeSelector = var.node_selector
        tolerations = var.tolerations
      }

      query_frontend = {
        replicas = 1
        resources = {
          requests = {
            cpu = "250m"
            memory = "256Mi"
          }
          limits = {
            cpu = "500m"
            memory = "512Mi"
          }
        }
        nodeSelector = var.node_selector
        tolerations = var.tolerations
      }

      compactor = {
        replicas = 1
        resources = var.mimir_resources
        nodeSelector = var.node_selector
        tolerations = var.tolerations
        persistence = {
          enabled = true
          size = "50Gi"
        }
      }

      store_gateway = {
        replicas = 1
        resources = var.mimir_resources
        nodeSelector = var.node_selector
        tolerations = var.tolerations
        persistence = {
          enabled = true
          size = "10Gi"
        }
      }

      nginx = {
        enabled = true
        replicas = 1
        service = {
          type = "ClusterIP"
        }
      }

      # Monitoring
      metaMonitoring = {
        serviceMonitor = {
          enabled = true
        }
        grafanaAgent = {
          enabled = false
        }
      }
    })
  ]

  depends_on = [var.cluster_dependency, kubernetes_namespace.observability]
}

# OpenTelemetry Collector
resource "helm_release" "otel_collector" {
  count            = var.enable_otel_collector ? 1 : 0
  name             = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = kubernetes_namespace.observability.metadata[0].name
  version          = var.otel_collector_version
  timeout          = 600
  create_namespace = false

  values = [
    yamlencode({
      mode = "deployment"
      replicaCount = 1
      
      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:4317"
              }
              http = {
                endpoint = "0.0.0.0:4318"
              }
            }
          }
        }
        
        processors = {
          batch = {}
        }
        
        exporters = {
          debug = {}
        }
        
        service = {
          pipelines = {
            traces = {
              receivers = ["otlp"]
              processors = ["batch"]
              exporters = ["debug"]
            }
          }
        }
      }

      resources = {
        limits = {
          cpu = "200m"
          memory = "256Mi"
        }
        requests = {
          cpu = "100m"
          memory = "128Mi"
        }
      }
    })
  ]

  depends_on = [helm_release.tempo]
}