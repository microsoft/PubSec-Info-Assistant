# Kubernetes namespace for the search service
resource "kubernetes_namespace" "search" {
  metadata {
    name = "search"
  }
}

# Kubernetes deployment for the search service
resource "kubernetes_deployment" "elasticsearch" {
  metadata {
    name      = "elasticsearch"
    namespace = kubernetes_namespace.search.metadata[0].name
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "elasticsearch"
      }
    }

    template {
      metadata {
        labels = {
          app = "elasticsearch"
        }
      }

      spec {
        container {
          name  = "elasticsearch"
          image = "localhost:5000/searchapp:latest"

          ports {
            container_port = 9200
          }

          env {
            name  = "discovery.type"
            value = "single-node"
          }
        }

        volume_mount {
          name       = "search-storage"
          mount_path = "/usr/share/elasticsearch/data"
        }
      }

      volume {
        name = "search-storage"

        host_path {
          path = "/mnt/data"
        }
      }
    }
  }
}

# Kubernetes service for the search service
resource "kubernetes_service" "elasticsearch" {
  metadata {
    name      = "elasticsearch-service"
    namespace = kubernetes_namespace.search.metadata[0].name
  }

  spec {
    selector = {
      app = "elasticsearch"
    }

    port {
      port        = 9200
      target_port = 9200
    }

    type = "LoadBalancer"
  }
}

# Kubernetes role assignment for container registry pull
resource "kubernetes_role_binding" "acr_pull_role" {
  metadata {
    name      = "acr-pull-role"
    namespace = kubernetes_namespace.search.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:registry"
  }

  subjects {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.search.metadata[0].name
  }
}

# Kubernetes secret for storage account access key
resource "kubernetes_secret" "storage_account" {
  metadata {
    name      = "storage-account-secret"
    namespace = kubernetes_namespace.search.metadata[0].name
  }

  data = {
    storage_account_access_key = base64encode("your_storage_account_access_key")
  }
}

# Kubernetes config map for search service settings
resource "kubernetes_config_map" "search_settings" {
  metadata {
    name      = "search-settings"
    namespace = kubernetes_namespace.search.metadata[0].name
  }

  data = {
    discovery.type = "single-node"
  }
}
