# Go API server: handles /api/* requests (auth, leaderboard, etc.). Ingress routes /api to this service.

resource "kubernetes_deployment" "api_server" {
  metadata {
    name      = "cow-api-server"
    namespace = var.namespace
    labels = {
      "app" = "cow-api"
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
        "app" = "cow-api"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "cow-api"
        }
      }

      spec {
        container {
          image             = var.api_server_image
          name              = "cowapiserver"
          image_pull_policy = var.api_server_image_pull_policy

          port {
            container_port = var.api_server_port
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "20m"
              memory = "64Mi"
            }
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
            value = var.postgres_user
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.postgres_password
          }
          env {
            name  = "POSTGRES_DB"
            value = var.postgres_db
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.redis, kubernetes_service.postgres]
}

resource "kubernetes_service" "api_server" {
  metadata {
    name      = "api-server"
    namespace = var.namespace
    labels = {
      "app" = "cow-api"
    }
  }

  spec {
    type = "ClusterIP"
    selector = {
      "app" = "cow-api"
    }
    port {
      port        = 80
      target_port = var.api_server_port
    }
  }
}
