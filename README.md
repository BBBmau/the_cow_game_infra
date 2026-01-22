# the cow game cluster
This repo is for managing the K8s Cluster used by `playthecowgame.com`

It involves using minikube for setting up a k8s cluster in a VM (currently this website is hosted on my mac mini on my desk).

The architecture is relatively simple. We provision two deployments with one representing the MMO server itself that players use with the second deployment being used as a database for keeping track of
player events as the server is running.

The service allows the communication between the redis server and game server itself to exist in order to allow data to be fetched when needed. (Such as wanting to display hay count)

The NodePort service is what exposes the Node to the public, in this case our minikube node address is exposed for users to use.

The PVC (Persistent Volume Claim) is of course what's used by redis to store the user data.

# How to setup

1. run `docker build -t mmo-server:local .` within the root of `the_cow_game` repo
2. Run `terraform apply`
2. run `minikube service the-cow-game-server` to run locally. (Redis setup soon)

## TODO:
 -[] support Grafana to analyze user data
 -[] add back PR support of creating testable changes
 -[] replace GKE entirely, only add back to expand server count
