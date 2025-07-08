output "namespace" {
  description = "Namespace where observability stack is deployed"
  value       = kubernetes_namespace.observability.metadata[0].name
}

output "loki_service_name" {
  description = "Loki service name"
  value       = var.enable_loki ? "loki-gateway" : null
}

output "loki_endpoint" {
  description = "Loki endpoint for Grafana data source"
  value       = var.enable_loki ? "http://loki-gateway.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local" : null
}

output "tempo_service_name" {
  description = "Tempo service name"
  value       = var.enable_tempo ? "tempo" : null
}

output "tempo_endpoint" {
  description = "Tempo endpoint for Grafana data source"
  value       = var.enable_tempo ? "http://tempo.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local:3200" : null
}

output "mimir_service_name" {
  description = "Mimir service name"
  value       = var.enable_mimir ? "mimir-nginx" : null
}

output "mimir_endpoint" {
  description = "Mimir endpoint for Grafana data source"
  value       = var.enable_mimir ? "http://mimir-nginx.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local" : null
}

output "otel_collector_endpoint" {
  description = "OpenTelemetry Collector endpoint"
  value       = var.enable_otel_collector ? "http://opentelemetry-collector.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local:4317" : null
}

output "prometheus_remote_write_endpoint" {
  description = "Mimir endpoint for Prometheus remote write"
  value       = var.enable_mimir ? "http://mimir-nginx.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local/api/v1/push" : null
}

output "services" {
  description = "All observability services information"
  value = {
    loki = {
      enabled   = var.enable_loki
      endpoint  = var.enable_loki ? "http://loki-gateway.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local" : null
      namespace = kubernetes_namespace.observability.metadata[0].name
    }
    tempo = {
      enabled   = var.enable_tempo
      endpoint  = var.enable_tempo ? "http://tempo.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local:3200" : null
      namespace = kubernetes_namespace.observability.metadata[0].name
    }
    mimir = {
      enabled          = var.enable_mimir
      query_endpoint   = var.enable_mimir ? "http://mimir-nginx.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local" : null
      write_endpoint   = var.enable_mimir ? "http://mimir-nginx.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local/api/v1/push" : null
      namespace        = kubernetes_namespace.observability.metadata[0].name
    }
    otel_collector = {
      enabled   = var.enable_otel_collector
      endpoint  = var.enable_otel_collector ? "http://opentelemetry-collector.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local:4317" : null
      namespace = kubernetes_namespace.observability.metadata[0].name
    }
  }
}

output "grafana_datasources_config" {
  description = "Grafana data sources configuration"
  value = {
    loki = var.enable_loki ? {
      name = "Loki"
      type = "loki"
      url  = "http://loki-gateway.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local"
      access = "proxy"
      isDefault = false
    } : null
    
    tempo = var.enable_tempo ? {
      name = "Tempo"
      type = "tempo"
      url  = "http://tempo.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local:3200"
      access = "proxy"
      isDefault = false
    } : null
    
    mimir = var.enable_mimir ? {
      name = "Mimir"
      type = "prometheus"
      url  = "http://mimir-nginx.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local"
      access = "proxy"
      isDefault = false
    } : null
  }
}

output "helm_releases" {
  description = "Deployed Helm releases"
  value = {
    loki              = var.enable_loki ? helm_release.loki[0].name : null
    promtail          = var.enable_promtail ? helm_release.promtail[0].name : null
    tempo             = var.enable_tempo ? helm_release.tempo[0].name : null
    mimir             = var.enable_mimir ? helm_release.mimir[0].name : null
    otel_collector    = var.enable_otel_collector ? helm_release.otel_collector[0].name : null
  }
}