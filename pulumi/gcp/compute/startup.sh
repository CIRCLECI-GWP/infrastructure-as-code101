#!/bin/bash
# Runs at every boot on Container-Optimized OS: starts the sample web app on port 8080.
CONTAINER_NAME="hello-app"
IMAGE="us-docker.pkg.dev/google-samples/containers/gke/hello-app:2.0"

iptables -w -A INPUT -p tcp --dport 8080 -j ACCEPT
docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true
docker run --detach --restart=always --name="$CONTAINER_NAME" -p 8080:8080 "$IMAGE"
