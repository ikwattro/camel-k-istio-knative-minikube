#!/bin/bash
minikube start --driver=virtualbox \
    --addons=dashboard \
    --addons=ingress \
    --addons=metrics-server \
    --addons=registry \
    --cpus 4

echo 'installing knative crds\n'
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.21.0/serving-crds.yaml

echo 'installing knative core\n'
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.21.0/serving-core.yaml

echo 'installing istio\n'
istioctl install -f istio/install.yml

echo 'installing knative istio\n'
kubectl apply --filename https://github.com/knative/net-istio/releases/download/v0.21.0/net-istio.yaml

echo 'labeling knative namespace\n'
kubectl label namespace knative-serving istio-injection=enabled

echo 'installing permissive settings\n'
kubectl apply -f istio/permissive.yml

echo 'installing knative istio controller\n'
kubectl apply --filename https://github.com/knative/net-istio/releases/download/v0.21.0/release.yaml

echo 'installing knative eventing\n'
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.21.0/eventing-crds.yaml

echo 'installing eventing core\n'
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.21.0/eventing-core.yaml

echo 'installing in memory channel\n'
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.21.0/in-memory-channel.yaml

echo 'installing mt channel broker\n'
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.21.0/mt-channel-broker.yaml

echo 'installing broker\n'
kubectl apply -f knative/broker.yml

echo 'installing kamel\n'
kamel install --force

