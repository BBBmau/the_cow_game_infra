output "redis_service" {
  value       = kubernetes_service.redis.metadata[0].name
  description = "Redis service name (use as REDIS_HOST from game server)."
}

output "postgres_service" {
  value       = kubernetes_service.postgres.metadata[0].name
  description = "PostgreSQL service name (use as POSTGRES_HOST from game server)."
}

output "game_server_service" {
  value       = kubernetes_service.game_server.metadata[0].name
  description = "Game server service name."
}

output "game_server_node_port" {
  value       = kubernetes_service.game_server.spec[0].port[0].node_port
  description = "NodePort for the game server. With minikube: minikube service single-pod-service --url. With Docker Desktop: localhost:<this_port>."
}

output "access_hint" {
  value       = "Game server: kubectl port-forward svc/single-pod-service 6060:80 -n ${var.namespace} then open http://localhost:6060 (or use NodePort from game_server_node_port)"
  description = "How to reach the game server locally."
}

output "ingress_hint" {
  value       = "Ingress: enable controller (e.g. minikube addons enable ingress), add '$(minikube ip 2>/dev/null || echo 127.0.0.1) ${var.ingress_host}' to /etc/hosts, then open http://${var.ingress_host} (/ -> web, /game -> game server)"
  description = "How to use local Ingress for path-based routing."
}
