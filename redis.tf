// Redis Deployment
resource "kubernetes_deployment" "redis" {
  metadata {
    name = "redis"
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

          # Redis configuration for persistence
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

          # Volume mount for persistence
          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }

          # Health check
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

        # Persistent volume for Redis data
        volume {
          name = "redis-data"
          persistent_volume_claim {
            claim_name = "redis-pvc"
          }
        }
      }
    }
  }
}

// Redis Service
resource "kubernetes_service" "redis" {
  metadata {
    name = "redis"
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

// Persistent Volume Claim for Redis
resource "kubernetes_persistent_volume_claim" "redis" {
  metadata {
    name = "redis-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}