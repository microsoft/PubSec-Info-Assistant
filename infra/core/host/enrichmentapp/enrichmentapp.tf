# Kubernetes namespace for the enrichment app
resource "kubernetes_namespace" "enrichment" {
  metadata {
    name = "enrichment"
  }
}

# Kubernetes deployment for the enrichment app
resource "kubernetes_deployment" "enrichment_app" {
  metadata {
    name      = "enrichment-app"
    namespace = kubernetes_namespace.enrichment.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "enrichment-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "enrichment-app"
        }
      }

      spec {
        container {
          name  = "enrichment-app"
          image = "localhost:5000/enrichmentapp:latest"

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
            name  = "BLOB_STORAGE_ACCOUNT"
            value = "minio"
          }

          env {
            name  = "BLOB_STORAGE_ACCOUNT_ENDPOINT"
            value = "http://minio-service:9000"
          }

          env {
            name  = "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"
            value = "upload"
          }

          env {
            name  = "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
            value = "output"
          }

          env {
            name  = "BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME"
            value = "logs"
          }

          env {
            name  = "AZURE_QUEUE_STORAGE_ENDPOINT"
            value = "http://minio-service:9000"
          }

          env {
            name  = "CHUNK_TARGET_SIZE"
            value = "500"
          }

          env {
            name  = "TARGET_PAGES"
            value = "10"
          }

          env {
            name  = "FR_API_VERSION"
            value = "v2.1"
          }

          env {
            name  = "AZURE_FORM_RECOGNIZER_ENDPOINT"
            value = "http://tesseract-service:80"
          }

          env {
            name  = "COSMOSDB_URL"
            value = "mongodb://mongodb-service:27017"
          }

          env {
            name  = "COSMOSDB_LOG_DATABASE_NAME"
            value = "logdb"
          }

          env {
            name  = "COSMOSDB_LOG_CONTAINER_NAME"
            value = "logcontainer"
          }

          env {
            name  = "PDF_SUBMIT_QUEUE"
            value = "pdfsubmitqueue"
          }

          env {
            name  = "PDF_POLLING_QUEUE"
            value = "pdfpollingqueue"
          }

          env {
            name  = "NON_PDF_SUBMIT_QUEUE"
            value = "nonpdfsubmitqueue"
          }

          env {
            name  = "MEDIA_SUBMIT_QUEUE"
            value = "mediasubmitqueue"
          }

          env {
            name  = "TEXT_ENRICHMENT_QUEUE"
            value = "textenrichmentqueue"
          }

          env {
            name  = "IMAGE_ENRICHMENT_QUEUE"
            value = "imageenrichmentqueue"
          }

          env {
            name  = "MAX_SECONDS_HIDE_ON_UPLOAD"
            value = "60"
          }

          env {
            name  = "MAX_SUBMIT_REQUEUE_COUNT"
            value = "5"
          }

          env {
            name  = "POLL_QUEUE_SUBMIT_BACKOFF"
            value = "30"
          }

          env {
            name  = "PDF_SUBMIT_QUEUE_BACKOFF"
            value = "30"
          }
        }

        volume_mount {
          name       = "enrichment-storage"
          mount_path = "/data"
        }
      }

      volume {
        name = "enrichment-storage"

        host_path {
          path = "/mnt/data"
        }
      }
    }
  }
}

# Kubernetes service for the enrichment app
resource "kubernetes_service" "enrichment_app" {
  metadata {
    name      = "enrichment-app-service"
    namespace = kubernetes_namespace.enrichment.metadata[0].name
  }

  spec {
    selector = {
      app = "enrichment-app"
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
    namespace = kubernetes_namespace.enrichment.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:registry"
  }

  subjects {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.enrichment.metadata[0].name
  }
}

# Kubernetes secret for storage account access key
resource "kubernetes_secret" "storage_account" {
  metadata {
    name      = "storage-account-secret"
    namespace = kubernetes_namespace.enrichment.metadata[0].name
  }

  data = {
    storage_account_access_key = base64encode("your_storage_account_access_key")
  }
}

# Kubernetes config map for enrichment app settings
resource "kubernetes_config_map" "enrichment_app_settings" {
  metadata {
    name      = "enrichment-app-settings"
    namespace = kubernetes_namespace.enrichment.metadata[0].name
  }

  data = {
    SCM_DO_BUILD_DURING_DEPLOYMENT            = "false"
    ENABLE_ORYX_BUILD                         = "false"
    APPLICATIONINSIGHTS_CONNECTION_STRING     = "your_application_insights_connection_string"
    KEY_EXPIRATION_DATE                       = "4320h"
    WEBSITE_PULL_IMAGE_OVER_VNET              = "false"
    WEBSITES_PORT                             = "6000"
    WEBSITES_CONTAINER_START_TIME_LIMIT       = "1600"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE       = "false"
  }
}
