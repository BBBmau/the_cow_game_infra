# Local Ingress: path-based routing like GKE (K8s.tf).
# Requires an Ingress controller: minikube addons enable ingress, or install ingress-nginx on kind/Docker Desktop.
# Then: add <cluster-ip> cow.local to /etc/hosts (e.g. minikube ip) and open http://cow.local
#
# /api -> Go API server (api-server.tf). Static assets (/, /style.css, etc.) -> web server.
# Styling/scripting work only if the web server app serves those files (e.g. express.static) and the
# mmo-web image includes the built CSS/JS in the path the server uses.

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
        # More specific paths first: /game -> game server, /api -> Go API server, / -> web server
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
        path {
          path      = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.api_server.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
        # Everything else (/, /static, etc.) -> web server
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
