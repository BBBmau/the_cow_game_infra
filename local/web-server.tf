// Web server: welcome, login, register, leaderboard, /user (not game)
resource "kubernetes_deployment" "web_server" {
  metadata {
    name = "the-cow-game-web"
    labels = {
      "app" = "cow-web"
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
        "app" = "cow-web"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "cow-web"
        }
      }

      spec {
        container {
          image             = var.web_server_image
          name  = "thecowgameweb"
          image_pull_policy = "Always"

          port {
            container_port = 6060
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "20m"
              memory = "128Mi"
            }
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

  depends_on = [kubernetes_service.postgres]
}

resource "kubernetes_service" "web_server" {
  metadata {
    name      = "web-server"
    namespace = var.namespace
  }
  spec {
    type = "ClusterIP"
    selector = {
      "app" = "cow-web"
    }
    port {
      port        = 80
      target_port = 6060
    }
  }
}