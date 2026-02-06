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

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `game_server_image` | `mmo-server:local` | Image for the cow game server. |
| `game_server_image_pull_policy` | `IfNotPresent` | Use `Never` for local-only images. |
| `namespace` | `default` | Namespace for all resources. |
| `kubeconfig_path` | `""` | Path to kubeconfig; empty = default. |

Example with a custom image:

```bash
terraform apply -var='game_server_image=mmo-server:debug' -var='game_server_image_pull_policy=Always'
```

## What this provisions

- **Redis**: deployment and ClusterIP service with ephemeral storage (emptyDir), so it starts immediately without a PVC or StorageClass.
- **Cow game server**: deployment and NodePort service (same shape as GKE `K8s.tf` but without GCP artifact registry or ingress).

No GCP resources, no GKE cluster, no ingress or TLS – only the app components so you can test and debug infra locally.

## Tear down

```bash
terraform destroy
```

State is stored in `local/terraform.tfstate` (local backend). You can delete it to start fresh; `terraform init` will reinitialize.
