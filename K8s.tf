terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
      version = "0.4.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "cow_game" {
  name = "cow-game-prod"
  # Multi-node for HA
  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    node {
        role = "control-plane"
        extra_port_mappings {
          container_port = 30080
          host_port      = 30080
          protocol       = "TCP"
        }
    }
    }
}

# Automatically load the local Docker image into the kind cluster
resource "null_resource" "load_image" {
  depends_on = [kind_cluster.cow_game]

  triggers = {
    cluster_name = kind_cluster.cow_game.name
    # Re-run if cluster is recreated
    cluster_id = kind_cluster.cow_game.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      docker save mmo-server:local | docker exec -i ${kind_cluster.cow_game.name}-control-plane ctr -n=k8s.io images import -
    EOT
  }
}

provider "kubernetes" {
  host                   = kind_cluster.cow_game.endpoint
  cluster_ca_certificate = kind_cluster.cow_game.cluster_ca_certificate
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
    kubernetes_service.redis,
    null_resource.load_image
  ]
}

// Redis Deployment
resource "kubernetes_deployment" "redis" {
  metadata {
    name = "redis"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "redis" }
    }
    template {
      metadata {
        labels = { app = "redis" }
      }
      spec {
        container {
          name  = "redis"
          image = "redis:alpine"
          port {
            container_port = 6379
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

resource "kubernetes_service" "redis" {
  metadata {
    name = "redis"
  }
  spec {
    selector = { app = "redis" }
    port {
      port = 6379
      target_port = 6379
    }
  }
  depends_on = [kubernetes_deployment.redis]
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
      node_port   = 30080
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
