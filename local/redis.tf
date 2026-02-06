# Redis for local debugging. Uses emptyDir instead of PVC so it comes up immediately
# without waiting for a StorageClass or "first consumer" binding (data is ephemeral).

resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels = {
      "app" = "redis"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "redis"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "redis"
        }
      }

      spec {
        container {
          image = "redis:7-alpine"
          name  = "redis"

          port {
            container_port = 6379
          }

          args = ["redis-server", "--appendonly", "yes"]

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
            name       = "redis-data"
            mount_path = "/data"
          }

          liveness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "redis-data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels = {
      "app" = "redis"
    }
  }

  spec {
    selector = {
      "app" = "redis"
    }

    port {
      port        = 6379
      target_port = 6379
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

