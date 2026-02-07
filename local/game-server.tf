# Cow game server – same logical setup as GKE (K8s.tf) but without GCP (no artifact registry secret).
# Uses var.game_server_image so you can run a local build (e.g. mmo-server:local).

resource "kubernetes_deployment" "game_server" {
  metadata {
    name      = "the-cow-game-server"
    namespace = var.namespace
    labels = {
      "app" = "cow-game"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    selector {
      match_labels = {
        "app" = "cow-game"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "cow-game"
        }
      }

      spec {
        container {
          image             = var.game_server_image
          name              = "thecowgameserver"
          image_pull_policy = var.game_server_image_pull_policy

          port {
            container_port = 6060
          }

          resources {
            limits = {
              cpu    = "750m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "20m"
              memory = "128Mi"
            }
          }

          env {
            name  = "NODE_OPTIONS"
            value = "--max-old-space-size=384"
          }

          env {
            name  = "REDIS_HOST"
            value = kubernetes_service.redis.metadata[0].name
          }

          env {
            name  = "REDIS_PORT"
            value = "6379"
          }

          env {
            name  = "POSTGRES_HOST"
            value = kubernetes_service.postgres.metadata[0].name
          }

          env {
            name  = "POSTGRES_PORT"
            value = "5432"
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
        }
      }
    }
  }

  depends_on = [kubernetes_service.redis, kubernetes_service.postgres]
}

resource "kubernetes_service" "game_server" {
  metadata {
    name      = "single-pod-service"
    namespace = var.namespace
  }

  spec {
    type = "NodePort"
    selector = {
      "app" = "cow-game"
    }
    port {
      port        = 80
      target_port = 6060
    }
  }
}
