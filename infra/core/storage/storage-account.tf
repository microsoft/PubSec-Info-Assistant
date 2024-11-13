# Kubernetes namespace for the storage service
resource "kubernetes_namespace" "storage" {
  metadata {
    name = "storage"
  }
}

# Kubernetes deployment for MinIO (S3-compatible storage)
resource "kubernetes_deployment" "minio" {
  metadata {
    name      = "minio"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "minio"
      }
    }

    template {
      metadata {
        labels = {
          app = "minio"
        }
      }

      spec {
        container {
          name  = "minio"
          image = "minio/minio:latest"

          ports {
            container_port = 9000
          }

          env {
            name  = "MINIO_ACCESS_KEY"
            value = "minioadmin"
          }

          env {
            name  = "MINIO_SECRET_KEY"
            value = "minioadmin"
          }

          command = ["minio", "server", "/data"]

          volume_mount {
            name       = "minio-storage"
            mount_path = "/data"
          }
        }

        volume {
          name = "minio-storage"

          host_path {
            path = "/mnt/data"
          }
        }
      }
    }
  }
}

# Kubernetes service for MinIO
resource "kubernetes_service" "minio" {
  metadata {
    name      = "minio-service"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }

  spec {
    selector = {
      app = "minio"
    }

    port {
      port        = 9000
      target_port = 9000
    }

    type = "LoadBalancer"
  }
}

# Kubernetes role assignment for container registry pull
resource "kubernetes_role_binding" "acr_pull_role" {
  metadata {
    name      = "acr-pull-role"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:registry"
  }

  subjects {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }
}

# Kubernetes secret for storage account access key
resource "kubernetes_secret" "storage_account" {
  metadata {
    name      = "storage-account-secret"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }

  data = {
    storage_account_access_key = base64encode("your_storage_account_access_key")
  }
}

# Kubernetes config map for storage settings
resource "kubernetes_config_map" "storage_settings" {
  metadata {
    name      = "storage-settings"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }

  data = {
    MINIO_ACCESS_KEY = "minioadmin"
    MINIO_SECRET_KEY = "minioadmin"
  }
}
