# CronJob: sync leaderboard data from Redis to Postgres.
# Uses a secret for DATABASE_URL; Redis host from the redis service.

resource "kubernetes_secret" "db_secret" {
  metadata {
    name      = "db-secret"
    namespace = var.namespace
  }
  data = {
    url = "postgresql://${var.postgres_user}:${var.postgres_password}@${kubernetes_service.postgres.metadata[0].name}:5432/${var.postgres_db}"
  }
}

resource "kubernetes_cron_job_v1" "sync_leaderboard" {
  metadata {
    name      = "sync-leaderboard"
    namespace = var.namespace
  }

  spec {
    schedule = var.sync_leaderboard_schedule

    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              name    = "sync"
              image   = var.sync_leaderboard_image
              command = ["node", "scripts/sync-leaderboard-to-postgres.js"]

              env {
                name = "DATABASE_URL"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.db_secret.metadata[0].name
                    key  = "url"
                  }
                }
              }
              env {
                name  = "REDIS_HOST"
                value = kubernetes_service.redis.metadata[0].name
              }
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.redis, kubernetes_service.postgres]
}
