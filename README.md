## Run Knative and Camel K on minikube

This repository contains the instructions to install and run `knative`, `istio`, `camel k` on `minikube`.

#### Create a minikube cluster

```bash
minikube start --driver=virtualbox \
    --addons=dashboard \
    --addons=ingress \
    --addons=metrics-server \
    --addons=registry \
    --cpus 4
```

#### Install Knative Resources and Components

```bash
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.19.0/serving-crds.yaml

kubectl apply --filename https://github.com/knative/serving/releases/download/v0.19.0/serving-core.yaml
```

#### Install Istio

Download and install the `istioctl` following the instructions [here](https://istio.io/latest/docs/setup/getting-started/#download)

Install `istio` without sidecar injection : 

```bash
istioctl install -f istio/install.yml
```

```bash
kubectl label namespace knative-serving istio-injection=enabled
```

Set peer authentication to permissive on `knative-serving` namespace : 

```bash
kubectl apply -f istio/permissive.yml
```

#### Install Knative Istio Controller

```bash
kubectl apply --filename https://github.com/knative/net-istio/releases/download/v0.19.0/release.yaml
```

Check PODs are running : 

```bash
kubectl get pods --namespace knative-serving
```

It should look like this : 

```bash
$ kubectl get pods --namespace knative-serving
NAME                                READY   STATUS    RESTARTS   AGE
activator-845748699b-kbc65          1/1     Running   0          62m
autoscaler-696d8868f4-2ctrz         1/1     Running   0          62m
controller-7f7566fbcb-dg4qb         1/1     Running   0          62m
istio-webhook-7dd7c94c7b-4t89r      1/1     Running   0          58m
networking-istio-85f6b5c894-p9nqj   1/1     Running   0          58m
webhook-54d6f984b4-b5vbj            1/1     Running   0          62m
```

#### Install Knative Eventing Resources and Components

```bash
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.19.0/eventing-crds.yaml

kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.19.0/eventing-core.yaml
```

#### Install a default InMemory channel

```bash
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.19.0/in-memory-channel.yaml
```

And a default broker 

```bash
kubectl apply --filename https://github.com/knative/eventing/releases/download/v0.19.0/mt-channel-broker.yaml
```

Check the Knative Eventing pods

```bash
kubectl get pods --namespace knative-eventing
```

And it should look like the following 

```
$ kubectl get pods --namespace knative-eventing
NAME                                    READY   STATUS    RESTARTS   AGE
eventing-controller-66c877b879-5k5p5    1/1     Running   0          62m
eventing-webhook-644c5c7667-qg4x9       1/1     Running   0          62m
imc-controller-587f98f97d-pwrxh         1/1     Running   0          62m
imc-dispatcher-6db95d7857-jtmtr         1/1     Running   0          62m
mt-broker-controller-76b65f7c96-pl2wt   1/1     Running   0          62m
mt-broker-filter-6bd64f8c65-jb5sz       1/1     Running   0          62m
mt-broker-ingress-7d8595d747-tfphr      1/1     Running   0          62m
```

#### Install Camel K

Download the Camel K CLI tool following the instructions [here](https://camel.apache.org/camel-k/latest/installation/installation.html#procedure)

Install `camel k` on the kubernetes cluster

```bash
kamel install --force
```

Check the operator is up and running 

```bash
$ kubectl get po

NAME                                READY   STATUS    RESTARTS   AGE
camel-k-operator-57bbcbd6dc-ds5pp   1/1     Running   0          63m

```

Configure the default broker 

```bash
kubectl apply -f knative/broker.yml
```

#### Run integrations

Run a test integration that just prints a line to the console logs :

```bash
kamel run integrations/hello.groovy --dev
```

After some time, the integration will run and will start to log outputs

```log
...
[1] 2020-12-31 11:47:11,624 INFO  [io.quarkus] (main) Profile prod activated.
[1] 2020-12-31 11:47:11,625 INFO  [io.quarkus] (main) Installed features: [camel-bean, camel-core, camel-endpointdsl, camel-k-core, camel-k-loader-groovy, camel-k-runtime, camel-log, camel-main, camel-support-common, camel-timer, cdi]
[1] 2020-12-31 11:47:12,634 INFO  [info] (Camel (camel-1) thread #0 - timer://tick) Exchange[ExchangePattern: InOnly, BodyType: String, Body: Hello world from Camel K]
[1] 2020-12-31 11:47:15,619 INFO  [info] (Camel (camel-1) thread #0 - timer://tick) Exchange[ExchangePattern: InOnly, BodyType: String, Body: Hello world from Camel K]
```

Now, let's run an integration that will listen to cloudevents of type `camel` in the default broker : 


```bash
kamel run integrations/kn.groovy --dev
```

The integration will start and remain idle, waiting for events to arrive : 

```log
[1] 2020-12-31 11:49:11,634 INFO  [io.quarkus] (main) Profile prod activated.
[1] 2020-12-31 11:49:11,634 INFO  [io.quarkus] (main) Installed features: [camel-attachments, camel-bean, camel-core, camel-endpointdsl, camel-k-core, camel-k-knative, camel-k-knative-consumer, camel-k-loader-groovy, camel-k-runtime, camel-log, camel-main, camel-platform-http, camel-support-common, cdi, mutiny, smallrye-context-propagation, vertx, vertx-web]
Condition "Ready" is "True" for Integration kn
```

To send events on the broker, we will deploy a `curl` pod, attach to it and send events with `curl`.

Open a new terminal window.

Deploy the curl pod : 

```bash
kubectl apply -f pods/curl.yml
```

Attach to the container

```bash
kubectl attach curl -it
```

And send a cloud event from it with the `camel` type : 

```bash
curl -v "http://broker-ingress.knative-eventing.svc.cluster.local/default/default" \
  -X POST \
  -H "ce-Id: 2222-ddd" \
  -H "ce-Specversion: 1.0" \
  -H "ce-Type: camel" \
  -H "content-type: application/json" \
  -d '{"firstName":"John", "lastName":"Doe"}'
```

And you should see the event logged from the integration : 

```log
[2] 2020-12-31 11:52:57,190 INFO  [io.quarkus] (main) Installed features: [camel-attachments, camel-bean, camel-core, camel-endpointdsl, camel-k-core, camel-k-knative, camel-k-knative-consumer, camel-k-loader-groovy, camel-k-runtime, camel-log, camel-main, camel-platform-http, camel-support-common, cdi, mutiny, smallrye-context-propagation, vertx, vertx-web]
[2] 2020-12-31 11:52:57,309 INFO  [info] (vert.x-worker-thread-0) Exchange[ExchangePattern: InOnly, BodyType: byte[], Body: {"firstName":"John", "lastName":"Doe"}]
```

#### Using Kamelets

This repository contains the same example as in the Camel K docs for the Telegram kamelet but instead make use of knative eventing without manually creating channels.

Deploy the telegram kamelet : 

```bash
kubectl apply -f kamelets/kamelet-telegram.yml
```

Create the bot token secret : 

```bash
kubectl create secret generic telegram --from-literal=BOT_TOKEN=XXXXXXXXX
```

Label the secret so it will be picked up by the integration 

```bash
kubectl label secret telegram camel.apache.org/kamelet=telegram-text-source
```

Run the kamelet binding ( which will create an integration under the hood )

```bash
kubectl apply -f kamelets/kamelet-binding.yml
```

Inspect the logs of the integration : 

```log
kamel log telegram-text-source-to-channel

[3] 2020-12-31 13:47:06,625 INFO  [io.quarkus] (main) Profile prod activated.
[3] 2020-12-31 13:47:06,626 INFO  [io.quarkus] (main) Installed features: [camel-attachments, camel-bean, camel-core, camel-direct, camel-endpointdsl, camel-k-core, camel-k-kamelet, camel-k-knative, camel-k-knative-producer, camel-k-loader-yaml, camel-k-runtime, camel-main, camel-platform-http, camel-support-ahc, camel-support-common, camel-support-webhook, camel-telegram, cdi, mutiny, smallrye-context-propagation, vertx, vertx-web]
[3] 2020-12-31 13:47:14,464 INFO  [telegram-text-source-695F2126EC562F3-0000000000000000] (Camel (camel-1) thread #0 - telegram://bots) john
[3] 2020-12-31 13:47:14,466 INFO  [telegram-text-source-695F2126EC562F3-0000000000000000] (Camel (camel-1) thread #0 - telegram://bots) {"firstName": "john", "lastName": "Joe"}
```

