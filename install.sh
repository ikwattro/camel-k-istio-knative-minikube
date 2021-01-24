#!/bin/bash
minikube start --driver=virtualbox \
    --addons=dashboard \
    --addons=ingress \
    --addons=metrics-server \
    --addons=registry \
    --cpus 4

kubectl apply --filename https://github.com/knative/serving/releases/download/v0.19.0/serving-crds.yaml

kubectl apply --filename https://github.com/knative/serving/releases/download/v0.19.0/serving-core.yaml

istioctl install -f istio/install.yml

kubectl label namespace knative-serving istio-injection=enabled

kubectl apply -f istio/permissive.yml

kubectl apply --filename https://github.com/knative/net-istio/releases/download/v0.19.0/release.yaml

kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.19.0/eventing-crds.yaml

kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.19.0/eventing-core.yaml

kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.19.0/in-memory-channel.yaml

kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.19.0/mt-channel-broker.yaml

kubectl apply -f knative/broker.yml

kamel install --force

