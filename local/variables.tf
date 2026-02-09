variable "kubeconfig_path" {
  type        = string
  default     = ""
  description = "Path to kubeconfig. Leave empty to use default (KUBECONFIG env or ~/.kube/config)."
}

variable "web_server_image" {
  type        = string
  default     = "mmo-web:local"
  description = "Docker image for the cow game web server. Use a local build (e.g. mmo-web:local) or any tag you push to your cluster."
}

variable "web_server_image_pull_policy" {
  type        = string
  default     = "IfNotPresent"
  description = "Image pull policy for the web server. Use IfNotPresent or Never for local images, Always when pulling from a registry."
}

variable "game_server_image" {
  type        = string
  default     = "mmo-server:local"
  description = "Docker image for the cow game server. Use a local build (e.g. mmo-server:local) or any tag you push to your cluster."
}

variable "game_server_image_pull_policy" {
  type        = string
  default     = "IfNotPresent"
  description = "Image pull policy for the game server. Use IfNotPresent or Never for local images, Always when pulling from a registry."
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Kubernetes namespace for local cow game resources."
}

variable "postgres_user" {
  type        = string
  default     = "postgres"
  description = "PostgreSQL user for the local database."
}

variable "postgres_password" {
  type        = string
  default     = "postgres"
  sensitive   = true
  description = "PostgreSQL password for local dev. Override via TF_VAR_postgres_password."
}

variable "postgres_db" {
  type        = string
  default     = "cowgame"
  description = "PostgreSQL database name used by the game server."
}

variable "ingress_host" {
  type        = string
  default     = "cow.local"
  description = "Host for local Ingress. Add this to /etc/hosts pointing at your cluster (e.g. minikube ip)."
}

variable "ingress_class_name" {
  type        = string
  default     = "nginx"
  description = "IngressClass name. Use 'nginx' for ingress-nginx (minikube addons enable ingress)."
}

variable "api_server_image" {
  type        = string
  default     = "cow-game-api:local"
  description = "Docker image for the Go API server. Use a local build (e.g. cow-api:local) or any tag you push to your cluster."
}

variable "api_server_image_pull_policy" {
  type        = string
  default     = "IfNotPresent"
  description = "Image pull policy for the API server. Use IfNotPresent or Never for local images."
}

variable "api_server_port" {
  type        = number
  default     = 8080
  description = "Port the Go API server listens on inside the container."
}

variable "sync_leaderboard_image" {
  type        = string
  default     = "mmo-db-sync:local"
  description = "Docker image for the leaderboard sync CronJob (must include Node and scripts/sync-leaderboard-to-postgres.js)."
}

variable "sync_leaderboard_schedule" {
  type        = string
  default     = "*/1 * * * *"
  description = "Cron schedule for Redis→Postgres leaderboard sync (default: every minute)."
}
