# Local cow game infrastructure

This directory provisions the same application stack as GKE (Redis + cow game server) on a **local Kubernetes cluster**. Use it to debug how the infra is managed without touching GCP.

## Prerequisites

- **kubectl** – [install](https://kubernetes.io/docs/tasks/tools/)
- **Terraform** – [install](https://developer.hashicorp.com/terraform/install)
- A local Kubernetes cluster and kubeconfig pointing at it, e.g.:
  - [minikube](https://minikube.sigs.k8s.io/docs/start/): `minikube start`
  - [kind](https://kind.sigs.k8s.io/): `kind create cluster`
  - Docker Desktop with Kubernetes enabled

Ensure your kubeconfig current context targets the local cluster:

```bash
kubectl config current-context
kubectl get nodes
```

## Quick start

1. **Build the game server image** from your game repo (e.g. `the_cow_game`):

   ```bash
   cd /path/to/the_cow_game   # or your game server repo
   docker build -t mmo-server:local .
   ```

   For **minikube**, load the image into the cluster:

   ```bash
   minikube image load mmo-server:local
   ```

   For **kind**:

   ```bash
   kind load docker-image mmo-server:local
   ```

   For **Docker Desktop** Kubernetes, the daemon is the same as your host, so no load step.

2. **Apply the local stack**:

   ```bash
   cd local
   terraform init
   terraform apply
   ```

3. **Reach the game server**:

   - **Port-forward** (works with any cluster):

     ```bash
     kubectl port-forward svc/single-pod-service 6060:80
     ```

     Then open http://localhost:6060 (or /game, /health, etc.).

   - **minikube**:

     ```bash
     minikube service single-pod-service --url
     ```

   - **NodePort**: after `terraform apply`, run `terraform output game_server_node_port` and open `http://localhost:<port>` (Docker Desktop / kind with port mapping).

4. **Optional – Ingress (path-based routing like GKE)**:

   Enable an Ingress controller, then use one host with paths:

   - **minikube**: `minikube addons enable ingress`
   - **kind / Docker Desktop**: install [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/) (e.g. via Helm or manifest).

   After `terraform apply`, add the Ingress host to `/etc/hosts`:

   ```bash
   # minikube
   echo "$(minikube ip) cow.local" | sudo tee -a /etc/hosts

   # kind (ingress-nginx with host ports): use 127.0.0.1
   echo "127.0.0.1 cow.local" | sudo tee -a /etc/hosts
   # kind (no host ports): use the control-plane container IP
   # echo "$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane) cow.local" | sudo tee -a /etc/hosts
   ```

   Then open **http://cow.local** (or the host from `ingress_host`). 

   The port needs to be specified that is used when running `kubectl port-forward`, for example if we use 6060 we would need to provide it as `http:cow.local:6060/game`

   - **http://cow.local/** → web server
   - **http://cow.local/game** → game server

   Override the host with `-var='ingress_host=myapp.local'` if needed.

   **If you get 503 (Service Temporarily Unavailable):** the Ingress controller can't reach the backends. Check that the game and web pods are running and that the Services have endpoints:

   ```bash
   kubectl get pods -n default -l 'app in (cow-game,cow-web)'
   kubectl get endpoints single-pod-service web-server -n default
   ```

   If endpoints are empty, fix the deployments (image pull, crash loops, etc.) and retry. Use **port 80** in the browser (e.g. http://cow.local), unless you explicitly exposed the Ingress controller on another port (e.g. NodePort 30600 → then http://cow.local:30600).

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `game_server_image` | `mmo-server:local` | Image for the cow game server. |
| `game_server_image_pull_policy` | `IfNotPresent` | Use `Never` for local-only images. |
| `namespace` | `default` | Namespace for all resources. |
| `kubeconfig_path` | `""` | Path to kubeconfig; empty = default. |
| `ingress_host` | `cow.local` | Host for local Ingress; add to /etc/hosts. |
| `ingress_class_name` | `nginx` | IngressClass (e.g. `nginx` for ingress-nginx). |

Example with a custom image:

```bash
terraform apply -var='game_server_image=mmo-server:debug' -var='game_server_image_pull_policy=Always'
```

## What this provisions

- **Redis**: deployment and ClusterIP service with ephemeral storage (emptyDir).
- **PostgreSQL**: deployment and ClusterIP service (ephemeral emptyDir) for the game server.
- **Cow game server**: deployment and NodePort service; connects to Redis and Postgres.
- **Web server**: deployment and ClusterIP service (welcome, login, leaderboard, etc.).
- **Ingress** (optional): path-based routing so **/** → web server and **/game** → game server, similar to GKE.

No GCP resources; use an Ingress controller in your local cluster to simulate production routing.

## Static assets (CSS, JS) on the index page

The cluster does **not** serve static files by itself. All requests that don’t start with `/game` (including `/`, `/style.css`, `/app.js`, `/static/*`, etc.) are sent to the **web server** pod. For styling and scripting to work you need:

1. **Web app serves static files** – The web server (e.g. Express) must serve CSS/JS, e.g. `express.static('public')` or similar, so that requests to `/style.css` or `/assets/main.js` are answered by the app.
2. **Image includes built assets** – The `mmo-web:local` image must contain the built frontend (CSS/JS) in the directory the server uses (e.g. `public/` or `dist/`). If the Dockerfile only copies `server.js` and not the built bundle, the browser will get 404 for `.css`/`.js`.

If the index loads but has no style or scripts, check the browser Network tab for 404s and fix the web app’s static serving and/or the web Dockerfile in the `the_cow_game` repo; no change is required in this infra.

## Tear down

```bash
terraform destroy
```

State is stored in `local/terraform.tfstate` (local backend). You can delete it to start fresh; `terraform init` will reinitialize.
