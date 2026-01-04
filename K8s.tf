provider "kubernetes" {
  host                   = "https://127.0.0.1:64145"
  cluster_ca_certificate = file("/Users/mau/.minikube/ca.crt")
}

// we moved away from pods in order to have auto provisioning every day - perhaps we can prevent this from happening
resource "kubernetes_deployment" "game_server" {
  metadata {
    name = "the-cow-game-server"
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
          image = "mmo-server:local"
          name  = "thecowgameserver"
          image_pull_policy = "Never"

          port {
            container_port = 6060
          }

          resources {
            limits = {
              cpu    = "750m"
              memory = "512Mi"  # Increased from 64Mi to support multiple players
            }
            requests = {
              cpu    = "20m"
              memory = "128Mi"  # Increased from 64Mi for baseline requirements
            }
          }

          # Add environment variables for better Node.js memory management
          env {
            name  = "NODE_OPTIONS"
            value = "--max-old-space-size=384"  # Set heap size to 384MB (75% of limit)
          }

          # Redis connection configuration
          env {
            name  = "REDIS_HOST"
            value = "redis"  # This matches the Redis service name
          }

          env {
            name  = "REDIS_PORT"
            value = "6379"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.redis
  ]
}

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

resource "kubernetes_service" "the_cow_game_server" {
  metadata {
    name = "the-cow-game-server"
  }

  spec {
    selector = {
      app = "cow-game"
    }

    type = "NodePort"

    port {
      port        = 80
      target_port = 6060
    }
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
