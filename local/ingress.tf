# Local Ingress: path-based routing like GKE (K8s.tf).
# Requires an Ingress controller: minikube addons enable ingress, or install ingress-nginx on kind/Docker Desktop.
# Then: add <cluster-ip> cow.local to /etc/hosts (e.g. minikube ip) and open http://cow.local

resource "kubernetes_ingress_v1" "local" {
  metadata {
    name      = "cow-local-ingress"
    namespace = var.namespace
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.ingress_host
      http {
        # More specific path first: /game -> game server
        path {
          path      = "/game"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.game_server.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
        # Everything else -> web server
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.web_server.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
