# Kubernetes namespace for the function app
resource "kubernetes_namespace" "functions" {
  metadata {
    name = "functions"
  }
}

# Kubernetes deployment for the function app
resource "kubernetes_deployment" "function_app" {
  metadata {
    name      = "function-app"
    namespace = kubernetes_namespace.functions.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "function-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "function-app"
        }
      }

      spec {
        container {
          name  = "function-app"
          image = "localhost:5000/functionapp:latest"

          ports {
            container_port = 80
          }

          env {
            name  = "FUNCTIONS_WORKER_RUNTIME"
            value = "python"
          }

          env {
            name  = "AzureWebJobsStorage"
            value = "DefaultEndpointsProtocol=https;AccountName=myaccount;AccountKey=mykey;EndpointSuffix=core.windows.net"
          }

          volume_mount {
            name       = "function-storage"
            mount_path = "/data"
          }
        }

        volume {
          name = "function-storage"

          host_path {
            path = "/mnt/data"
          }
        }
      }
    }
  }
}

# Kubernetes service for the function app
resource "kubernetes_service" "function_app" {
  metadata {
    name      = "function-app-service"
    namespace = kubernetes_namespace.functions.metadata[0].name
  }

  spec {
    selector = {
      app = "function-app"
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
    namespace = kubernetes_namespace.functions.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:registry"
  }

  subjects {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.functions.metadata[0].name
  }
}

# Kubernetes secret for storage account access key
resource "kubernetes_secret" "storage_account" {
  metadata {
    name      = "storage-account-secret"
    namespace = kubernetes_namespace.functions.metadata[0].name
  }

  data = {
    storage_account_access_key = base64encode("your_storage_account_access_key")
  }
}

# Kubernetes config map for function app settings
resource "kubernetes_config_map" "function_app_settings" {
  metadata {
    name      = "function-app-settings"
    namespace = kubernetes_namespace.functions.metadata[0].name
  }

  data = {
    FUNCTIONS_WORKER_RUNTIME                    = "python"
    FUNCTIONS_EXTENSION_VERSION                 = "~4"
    WEBSITE_NODE_DEFAULT_VERSION                = "~14"
    APPLICATIONINSIGHTS_CONNECTION_STRING       = "your_application_insights_connection_string"
    APPINSIGHTS_INSTRUMENTATIONKEY              = "your_application_insights_instrumentation_key"
    BLOB_STORAGE_ACCOUNT                        = "minio"
    BLOB_STORAGE_ACCOUNT_ENDPOINT               = "http://minio-service:9000"
    BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME  = "upload"
    BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME  = "output"
    BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME     = "logs"
    AZURE_QUEUE_STORAGE_ENDPOINT                = "http://minio-service:9000"
    CHUNK_TARGET_SIZE                           = "500"
    TARGET_PAGES                                = "10"
    FR_API_VERSION                              = "v2.1"
    AZURE_FORM_RECOGNIZER_ENDPOINT              = "http://tesseract-service:80"
    COSMOSDB_URL                                = "mongodb://mongodb-service:27017"
    COSMOSDB_LOG_DATABASE_NAME                  = "logdb"
    COSMOSDB_LOG_CONTAINER_NAME                 = "logcontainer"
    PDF_SUBMIT_QUEUE                            = "pdfsubmitqueue"
    PDF_POLLING_QUEUE                           = "pdfpollingqueue"
    NON_PDF_SUBMIT_QUEUE                        = "nonpdfsubmitqueue"
    MEDIA_SUBMIT_QUEUE                          = "mediasubmitqueue"
    TEXT_ENRICHMENT_QUEUE                       = "textenrichmentqueue"
    IMAGE_ENRICHMENT_QUEUE                      = "imageenrichmentqueue"
    MAX_SECONDS_HIDE_ON_UPLOAD                  = "60"
    MAX_SUBMIT_REQUEUE_COUNT                    = "5"
    POLL_QUEUE_SUBMIT_BACKOFF                   = "30"
    PDF_SUBMIT_QUEUE_BACKOFF                    = "30"
  }
}
