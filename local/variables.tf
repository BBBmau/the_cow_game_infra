variable "kubeconfig_path" {
  type        = string
  default     = ""
  description = "Path to kubeconfig. Leave empty to use default (KUBECONFIG env or ~/.kube/config)."
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
