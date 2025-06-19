output "nginx_ingress_namespace" {
  description = "Namespace of the nginx ingress controller"
  value       = var.enable_nginx_ingress ? var.ingress_namespace : null
}

output "cert_manager_namespace" {
  description = "Namespace of cert-manager"
  value       = var.enable_cert_manager ? var.cert_manager_namespace : null
}

output "monitoring_namespace" {
  description = "Namespace of the monitoring stack"
  value       = var.enable_prometheus_stack ? var.monitoring_namespace : null
}

output "argocd_namespace" {
  description = "Namespace of ArgoCD"
  value       = var.enable_argocd ? var.argocd_namespace : null
}

output "velero_namespace" {
  description = "Namespace of Velero"
  value       = var.enable_velero ? var.velero_namespace : null
}

output "helm_releases" {
  description = "List of deployed Helm releases"
  value = {
    nginx_ingress        = var.enable_nginx_ingress ? helm_release.nginx_ingress[0].name : null
    cert_manager         = var.enable_cert_manager ? helm_release.cert_manager[0].name : null
    external_dns         = var.enable_external_dns ? helm_release.external_dns[0].name : null
    prometheus_stack     = var.enable_prometheus_stack ? helm_release.kube_prometheus_stack[0].name : null
    argocd              = var.enable_argocd ? helm_release.argocd[0].name : null
    velero              = var.enable_velero ? helm_release.velero[0].name : null
    cluster_autoscaler  = var.enable_cluster_autoscaler ? helm_release.cluster_autoscaler[0].name : null
    keda                = var.enable_keda ? helm_release.keda[0].name : null
    azure_key_vault_csi = var.enable_azure_key_vault_csi ? helm_release.azure_key_vault_csi[0].name : null
  }
}