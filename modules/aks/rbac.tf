# Kubernetes RBAC Configuration
resource "kubernetes_cluster_role" "custom" {
  for_each = var.k8s_cluster_roles
  
  metadata {
    name   = each.key
    labels = each.value.labels
  }
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_role" "custom" {
  for_each = var.k8s_roles
  
  metadata {
    name      = each.key
    namespace = each.value.namespace
    labels    = each.value.labels
  }
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_cluster_role_binding" "custom" {
  for_each = var.k8s_cluster_role_bindings
  
  metadata {
    name   = each.key
    labels = each.value.labels
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = each.value.role_name
  }
  
  dynamic "subject" {
    for_each = each.value.subjects
    content {
      kind      = subject.value.kind
      name      = subject.value.name
      namespace = lookup(subject.value, "namespace", null)
      api_group = subject.value.kind == "Group" || subject.value.kind == "User" ? "rbac.authorization.k8s.io" : null
    }
  }
}

resource "kubernetes_role_binding" "custom" {
  for_each = var.k8s_role_bindings
  
  metadata {
    name      = each.key
    namespace = each.value.namespace
    labels    = each.value.labels
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = each.value.role_kind
    name      = each.value.role_name
  }
  
  dynamic "subject" {
    for_each = each.value.subjects
    content {
      kind      = subject.value.kind
      name      = subject.value.name
      namespace = lookup(subject.value, "namespace", null)
      api_group = subject.value.kind == "Group" || subject.value.kind == "User" ? "rbac.authorization.k8s.io" : null
    }
  }
}