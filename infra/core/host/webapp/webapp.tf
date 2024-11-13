# Kubernetes namespace for the web app
resource "kubernetes_namespace" "webapp" {
  metadata {
    name = "webapp"
  }
}

# Kubernetes deployment for the web app
resource "kubernetes_deployment" "webapp" {
  metadata {
    name      = "webapp"
    namespace = kubernetes_namespace.webapp.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "webapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "webapp"
        }
      }

      spec {
        container {
          name  = "webapp"
          image = "localhost:5000/webapp:latest"

          ports {
            container_port = 80
          }

          env {
            name  = "FUNCTIONS_WORKER_RUNTIME"
            value = "python"
          }

          env {
            name  = "WEBSITE_RUN_FROM_PACKAGE"
            value = "1"
          }

          env {
            name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
            value = "your_application_insights_connection_string"
          }

          env {
            name  = "APPINSIGHTS_INSTRUMENTATIONKEY"
            value = "your_application_insights_instrumentation_key"
          }

          env {
            name  = "BING_SEARCH_KEY"
            value = "your_bing_search_key"
          }

          env {
            name  = "WEBSITES_PORT"
            value = "6000"
          }

          env {
            name  = "WEBSITES_CONTAINER_START_TIME_LIMIT"
            value = "1600"
          }

          env {
            name  = "WEBSITES_ENABLE_APP_SERVICE_STORAGE"
            value = "false"
          }
        }

        volume_mount {
          name       = "webapp-storage"
          mount_path = "/data"
        }
      }

      volume {
        name = "webapp-storage"

        host_path {
          path = "/mnt/data"
        }
      }
    }
  }
}

# Kubernetes service for the web app
resource "kubernetes_service" "webapp" {
  metadata {
    name      = "webapp-service"
    namespace = kubernetes_namespace.webapp.metadata[0].name
  }

  spec {
    selector = {
      app = "webapp"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

# Kubernetes role assignment for container registry pull
resource "kubernetes_role_binding" "acr_pull_role" {
  metadata {
    name      = "acr-pull-role"
    namespace = kubernetes_namespace.webapp.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:registry"
  }

  subjects {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.webapp.metadata[0].name
  }
}

# Kubernetes secret for storage account access key
resource "kubernetes_secret" "storage_account" {
  metadata {
    name      = "storage-account-secret"
    namespace = kubernetes_namespace.webapp.metadata[0].name
  }

  data = {
    storage_account_access_key = base64encode("your_storage_account_access_key")
  }
}

# Kubernetes config map for web app settings
resource "kubernetes_config_map" "webapp_settings" {
  metadata {
    name      = "webapp-settings"
    namespace = kubernetes_namespace.webapp.metadata[0].name
  }

  data = {
    SCM_DO_BUILD_DURING_DEPLOYMENT            = "false"
    ENABLE_ORYX_BUILD                         = "false"
    APPLICATIONINSIGHTS_CONNECTION_STRING     = "your_application_insights_connection_string"
    BING_SEARCH_KEY                           = "your_bing_search_key"
    WEBSITE_PULL_IMAGE_OVER_VNET              = "false"
    WEBSITES_PORT                             = "6000"
    WEBSITES_CONTAINER_START_TIME_LIMIT       = "1600"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE       = "false"
  }
}
