# PostgreSQL for local debugging. Uses emptyDir so it comes up immediately
# without waiting for a StorageClass (data is ephemeral). Game server connects via POSTGRES_HOST/POSTGRES_PORT.

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "default"
    labels = {
      "app" = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "postgres"
        }
      }

      spec {
        container {
          image = "postgres:16-alpine"
          name  = "postgres"

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name  = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "database"
              }
            }
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "10m"
              memory = "64Mi"
            }
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

        }

        volume {
          name = "postgres-data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "default"
    labels = {
      "app" = "postgres"
    }
  }

  spec {
    selector = {
      "app" = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
