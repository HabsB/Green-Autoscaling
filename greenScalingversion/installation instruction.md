# Install with Azure Kubernetes Service

## Prerequisites

* An Azure Subscription (e.g. [Free](https://aka.ms/azure-free-account) or [Student](https://aka.ms/azure-student-account) account)
* [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) with [Azure Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install#azure-cli) installed
* [Git CLI](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* [`kubectl` CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* [Helm CLI](https://helm.sh/docs/intro/install/)
* Bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc)
* OPTIONAL: [Terraform CLI](https://www.terraform.io/downloads)

> If you do not have all the tools listed above, you can launch the [GitHub Codespaces](https://github.com/features/codespaces) environment which has all the tools pre-installed.

## Clone repo

Use Git CLI to clone this repo and drop into the directory

```bash
git clone https://github.com/HabsB/Green-Autoscaling/tree/main/greenScalingversion
cd Green-Autoscaling
```

## Deploy Azure Infrastructure

You have the option to deploy Azure resources using Azure CLI or Terraform. Depending on which option you choose, click the appropriate heading to expand instructions for each.

> Regardless of the option you choose, you will need to login to Azure using the `az login` command before you begin

<details>
<summary>Azure CLI</summary>

Create a resource group where Azure Cache for Redis and Azure Kubernetes Service will be deployed into

```bash
RAND=$RANDOM
RESOURCE_GROUP=rg-carbonaware-demo-$RAND
LOCATION=westus
CLUSTER_NAME=carbonaware-demo-$RAND

az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

Azure Kubernetes Service is where we'll deploy and test this operator

```bash
az aks create \
 --resource-group $RESOURCE_GROUP \
 --name $CLUSTER_NAME \
 --node-count 1 \
 --node-vm-size Standard_DS3_v2 \
 --generate-ssh-keys \
 --node-osdisk-type Ephemeral \
 --enable-cluster-autoscaler \
 --min-count 1 \
 --max-count 10
```

> This service can take 7-10 minutes to provision

</details>
<br/>

<details>
<summary>Terraform</summary>

This repo includes a sample terraform file to deploy Azure Cache for Redis and Azure Kubernetes Service with the following commands

```bash
# drop into proper directory
cd hack/azure/terraform

# initialize terraform plugins
terraform init

# deploy resources
terraform apply

# set variables to connect to aks cluster
export RESOURCE_GROUP=$(terraform output -raw green_name)
export LOCATION=$(terraform output -raw green_location)
export CLUSTER_NAME=$(terraform output -raw aks_name)

export RESOURCE_GROUP=$(terraform output -raw legacy_name)
export LOCATION=$(terraform output -raw legacy_location)
export CLUSTER_NAME=$(terraform output -raw aks_name)


# get back to repository root 
cd ../../../
```

> This deployment can take 15-20 minutes to provision.

</details>
<br/>

Retrieve the `.kube/config` file.

```bash
az aks get-credentials \
 --resource-group $RESOURCE_GROUP \
 --name $CLUSTER_NAME
```

Test your connectivity to the AKS cluster.

```bash
kubectl cluster-info
```

## Install KEDA

As the name suggest, KEDA is a requirement for this operator. A sample manifest is available in this repo to install KEDA v2.10.0.

```bash
kubectl apply -f greenScalingversion/keda-2.10.0.yaml

# wait for external metrics
kubectl wait --for=condition=Available --timeout=600s apiservice v1beta1.external.metrics.k8s.io
```

## Deploy the SockShop Microservices Web Application

```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: sock-shop-g
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: carts
  labels:
    name: carts
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: carts
  template:
    metadata:
      labels:
        name: carts
    spec:
      containers:
      - name: carts
        image: weaveworksdemos/carts:0.4.8
        env:
         - name: JAVA_OPTS
           value: -Xms64m -Xmx128m -XX:+UseG1GC -Djava.security.egd=file:/dev/urandom -Dspring.zipkin.enabled=false
        resources:
          limits:
            cpu: 300m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
        ports:
        - containerPort: 80
        securityContext:
          runAsNonRoot: true
          runAsUser: 10001
          capabilities:
            drop:
              - all
            add:
              - NET_BIND_SERVICE
          readOnlyRootFilesystem: true
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
      volumes:
        - name: tmp-volume
          emptyDir:
            medium: Memory
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: carts
  annotations:
        prometheus.io/scrape: 'true'
  labels:
    name: carts
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 80
    targetPort: 80
  selector:
    name: carts
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: carts-db
  labels:
    name: carts-db
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: carts-db
  template:
    metadata:
      labels:
        name: carts-db
    spec:
      containers:
      - name: carts-db
        image: mongo
        ports:
        - name: mongo
          containerPort: 27017
        securityContext:
          capabilities:
            drop:
              - all
            add:
              - CHOWN
              - SETGID
              - SETUID
          readOnlyRootFilesystem: true
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
      volumes:
        - name: tmp-volume
          emptyDir:
            medium: Memory
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: carts-db
  labels:
    name: carts-db
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 27017
    targetPort: 27017
  selector:
    name: carts-db
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalogue
  labels:
    name: catalogue
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: catalogue
  template:
    metadata:
      labels:
        name: catalogue
    spec:
      containers:
      - name: catalogue
        image: weaveworksdemos/catalogue:0.3.5
        command: ["/app"]
        args:
        - -port=80
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 80
        securityContext:
          runAsNonRoot: true
          runAsUser: 10001
          capabilities:
            drop:
              - all
            add:
              - NET_BIND_SERVICE
          readOnlyRootFilesystem: true
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 300
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 180
          periodSeconds: 3
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: catalogue
  annotations:
        prometheus.io/scrape: 'true'
  labels:
    name: catalogue
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 80
    targetPort: 80
  selector:
    name: catalogue
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalogue-db
  labels:
    name: catalogue-db
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: catalogue-db
  template:
    metadata:
      labels:
        name: catalogue-db
    spec:
      containers:
      - name: catalogue-db
        image: weaveworksdemos/catalogue-db:0.3.0
        env:
          - name: MYSQL_ROOT_PASSWORD
            value: fake_password
          - name: MYSQL_DATABASE
            value: socksdb
        ports:
        - name: mysql
          containerPort: 3306
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: catalogue-db
  labels:
    name: catalogue-db
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 3306
    targetPort: 3306
  selector:
    name: catalogue-db
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: front-end
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: front-end
  template:
    metadata:
      labels:
        name: front-end
    spec:
      containers:
      - name: front-end
        image: weaveworksdemos/front-end:0.3.12
        resources:
          limits:
            cpu: 300m
            memory: 1000Mi
          requests:
            cpu: 100m
            memory: 300Mi
        ports:
        - containerPort: 8079
        env:
        - name: SESSION_REDIS
          value: "true"
        securityContext:
          runAsNonRoot: true
          runAsUser: 10001
          capabilities:
            drop:
              - all
          readOnlyRootFilesystem: true
        livenessProbe:
          httpGet:
            path: /
            port: 8079
          initialDelaySeconds: 300
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: /
            port: 8079
          initialDelaySeconds: 30
          periodSeconds: 3
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: front-end
  annotations:
        prometheus.io/scrape: 'true'
  labels:
    name: front-end
  namespace: sock-shop-g
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8079
    nodePort: 30001
  selector:
    name: front-end
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-external
  namespace: sock-shop-g
spec:
  type: LoadBalancer
  selector:
    name: front-end
  ports:
  - name: http
    port: 80
    targetPort: 8079
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders
  labels:
    name: orders
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: orders
  template:
    metadata:
      labels:
        name: orders
    spec:
      containers:
      - name: orders
        image: weaveworksdemos/orders:0.4.7
        env:
         - name: JAVA_OPTS
           value: -Xms64m -Xmx128m -XX:+UseG1GC -Djava.security.egd=file:/dev/urandom -Dspring.zipkin.enabled=false
        resources:
          limits:
            cpu: 500m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 300Mi
        ports:
        - containerPort: 80
        securityContext:
          runAsNonRoot: true
          runAsUser: 10001
          capabilities:
            drop:
              - all
            add:
              - NET_BIND_SERVICE
          readOnlyRootFilesystem: true
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
      volumes:
        - name: tmp-volume
          emptyDir:
            medium: Memory
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: orders
  annotations:
        prometheus.io/scrape: 'true'
  labels:
    name: orders
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 80
    targetPort: 80
  selector:
    name: orders
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-db
  labels:
    name: orders-db
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: orders-db
  template:
    metadata:
      labels:
        name: orders-db
    spec:
      containers:
      - name: orders-db
        image: mongo
        ports:
        - name: mongo
          containerPort: 27017
        securityContext:
          capabilities:
            drop:
              - all
            add:
              - CHOWN
              - SETGID
              - SETUID
          readOnlyRootFilesystem: true
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
      volumes:
        - name: tmp-volume
          emptyDir:
            medium: Memory
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: orders-db
  labels:
    name: orders-db
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 27017
    targetPort: 27017
  selector:
    name: orders-db
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment
  labels:
    name: payment
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: payment
  template:
    metadata:
      labels:
        name: payment
    spec:
      containers:
      - name: payment
        image: weaveworksdemos/payment:0.4.3
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 99m
            memory: 100Mi
        ports:
        - containerPort: 80
        securityContext:
          runAsNonRoot: true
          runAsUser: 10001
          capabilities:
            drop:
              - all
            add:
              - NET_BIND_SERVICE
          readOnlyRootFilesystem: true
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 300
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 180
          periodSeconds: 3
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: payment
  annotations:
        prometheus.io/scrape: 'true'
  labels:
    name: payment
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 80
    targetPort: 80
  selector:
    name: payment
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: queue-master
  labels:
    name: queue-master
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: queue-master
  template:
    metadata:
      labels:
        name: queue-master
    spec:
      containers:
      - name: queue-master
        image: weaveworksdemos/queue-master:0.3.1
        env:
         - name: JAVA_OPTS
           value: -Xms64m -Xmx128m -XX:+UseG1GC -Djava.security.egd=file:/dev/urandom -Dspring.zipkin.enabled=false
        resources:
          limits:
            cpu: 300m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 300Mi
        ports:
        - containerPort: 80
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: queue-master
  annotations:
        prometheus.io/scrape: 'true'
  labels:
    name: queue-master
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 80
    targetPort: 80
  selector:
    name: queue-master
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq
  labels:
    name: rabbitmq
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: rabbitmq
  template:
    metadata:
      labels:
        name: rabbitmq
      annotations:
        prometheus.io/scrape: "false"
    spec:
      containers:
      - name: rabbitmq
        image: rabbitmq:3.6.8-management
        ports:
        - containerPort: 15672
          name: management
        - containerPort: 5672
          name: rabbitmq
        securityContext:
          capabilities:
            drop:
              - all
            add:
              - CHOWN
              - SETGID
              - SETUID
              - DAC_OVERRIDE
          readOnlyRootFilesystem: true
      - name: rabbitmq-exporter
        image: kbudde/rabbitmq-exporter
        ports:
        - containerPort: 9090
          name: exporter
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
  annotations:
        prometheus.io/scrape: 'true'
        prometheus.io/port: '9090'
  labels:
    name: rabbitmq
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 5672
    name: rabbitmq
    targetPort: 5672
  - port: 9090
    name: exporter
    targetPort: exporter
    protocol: TCP
  selector:
    name: rabbitmq
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: session-db
  labels:
    name: session-db
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: session-db
  template:
    metadata:
      labels:
        name: session-db
      annotations:
        prometheus.io.scrape: "false"
    spec:
      containers:
      - name: session-db
        image: redis:alpine
        ports:
        - name: redis
          containerPort: 6379
        securityContext:
          capabilities:
            drop:
              - all
            add:
              - CHOWN
              - SETGID
              - SETUID
          readOnlyRootFilesystem: true
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: session-db
  labels:
    name: session-db
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 6379
    targetPort: 6379
  selector:
    name: session-db
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shipping
  labels:
    name: shipping
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: shipping
  template:
    metadata:
      labels:
        name: shipping
    spec:
      containers:
      - name: shipping
        image: weaveworksdemos/shipping:0.4.8
        env:
         - name: ZIPKIN
           value: zipkin.jaeger.svc.cluster.local
         - name: JAVA_OPTS
           value: -Xms64m -Xmx128m -XX:+UseG1GC -Djava.security.egd=file:/dev/urandom -Dspring.zipkin.enabled=false
        resources:
          limits:
            cpu: 300m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 300Mi
        ports:
        - containerPort: 80
        securityContext:
          runAsNonRoot: true
          runAsUser: 10001
          capabilities:
            drop:
              - all
            add:
              - NET_BIND_SERVICE
          readOnlyRootFilesystem: true
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
      volumes:
        - name: tmp-volume
          emptyDir:
            medium: Memory
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: shipping
  annotations:
        prometheus.io/scrape: 'true'
  labels:
    name: shipping
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 80
    targetPort: 80
  selector:
    name: shipping

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user
  labels:
    name: user
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: user
  template:
    metadata:
      labels:
        name: user
    spec:
      containers:
      - name: user
        image: weaveworksdemos/user:0.4.7
        resources:
          limits:
            cpu: 300m
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 80
        env:
        - name: mongo
          value: user-db:27017
        securityContext:
          runAsNonRoot: true
          runAsUser: 10001
          capabilities:
            drop:
              - all
            add:
              - NET_BIND_SERVICE
          readOnlyRootFilesystem: true
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 300
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 180
          periodSeconds: 3
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: user
  annotations:
        prometheus.io/scrape: 'true'
  labels:
    name: user
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 80
    targetPort: 80
  selector:
    name: user

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-db
  labels:
    name: user-db
  namespace: sock-shop-g
spec:
  replicas: 1
  selector:
    matchLabels:
      name: user-db
  template:
    metadata:
      labels:
        name: user-db
    spec:
      containers:
      - name: user-db
        image: weaveworksdemos/user-db:0.3.0

        ports:
        - name: mongo
          containerPort: 27017
        securityContext:
          capabilities:
            drop:
              - all
            add:
              - CHOWN
              - SETGID
              - SETUID
          readOnlyRootFilesystem: true
        volumeMounts:
        - mountPath: /tmp
          name: tmp-volume
      volumes:
        - name: tmp-volume
          emptyDir:
            medium: Memory
      nodeSelector:
        beta.kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: user-db
  labels:
    name: user-db
  namespace: sock-shop-g
spec:
  ports:
    # the port that this service should serve on
  - port: 27017
    targetPort: 27017
  selector:
    name: user-db
EOF

# note the number of replicas that are ready
kubectl get deploy word-processor
```

Finally, scale the `word-processor` app using KEDA's Redis trigger.

```bash
kubectl apply -f - <<EOF 
apiVersion: keda.sh/v1alpha1 
kind: ScaledObject 
metadata: 
  name: word-processor-scaler
spec: 
  scaleTargetRef: 
    apiVersion: apps/v1                             # Optional. Default: apps/v1 
    kind: deployment                                # Optional. Default: Deployment 
    name: word-processor                            # Mandatory. Must be in the same namespace as the ScaledObject 
    envSourceContainerName: word-processor          # Optional. Default: .spec.template.spec.containers[0] 
  pollingInterval: 30                               # Optional. Default: 30 seconds 
  cooldownPeriod:  120                              # Optional. Default: 300 seconds 
  minReplicaCount: 0                                # Optional. Default: 0 
  maxReplicaCount: 100                              # Optional. Default: 100 
  advanced:                                         # Optional. Section to specify advanced options 
    restoreToOriginalReplicaCount: false            # Optional. Default: false 
    horizontalPodAutoscalerConfig:                  # Optional. Section to specify HPA related options 
      behavior:                                     # Optional. Use to modify HPA's scaling behavior 
        scaleDown: 
          stabilizationWindowSeconds: 300 
          policies: 
          - type: Percent 
            value: 100 
            periodSeconds: 15 
  triggers: 
  - type: redis 
    metadata:
      hostFromEnv: REDIS_HOST 
      portFromEnv: REDIS_PORT
      passwordFromEnv: REDIS_KEY 
      listName: words 
      listLength: "500"
      enableTLS: "false"
      databaseIndex: "0"
EOF
# wait a few seconds and note the number of replicas that are ready now
kubectl get deploy word-processor -w
```

## Install Carbon Intensity Exporter Operator

To test with real data from the Carbon Aware SDK, head over to this [repo](https://github.com/Azure/kubernetes-carbon-intensity-exporter/) and follow the instructions in the [README.md](https://github.com/Azure/kubernetes-carbon-intensity-exporter/blob/main/README.md) to install the operator into the AKS cluster.

> IMPORTANT: You must have WattTime API credentials to use this operator

If you do not have WattTime API credentials you can skip this step and still test this operator using mock carbon intensity data

```bash
cd /tmp
git clone https://github.com/Azure/kubernetes-carbon-intensity-exporter.git
cd kubernetes-carbon-intensity-exporter
```

Using Helm, install the Carbon Intensity Exporter Operator into the AKS cluster.

```bash
export WATTTIME_USERNAME="DanB" 
export WATTTIME_PASSWORD="aj)NwBf~IbF+"
export REGION=westus

export WATTTIME_USERNAME=HabenB 
export WATTTIME_PASSWORD=Haben@717
export REGION=westus

helm install carbon-intensity-exporter \
  --set carbonDataExporter.region=$LOCATION \
  --set apiServer.username=$WATTTIME_USERNAME \
  --set apiServer.password=$WATTTIME_PASSWORD \
  ./charts/carbon-intensity-exporter



# go back to repo directory
cd /workspaces/carbon-aware-keda-operator
```

Verify carbon intensity data is in place.

```bash
# ensure the status of the carbon intensity exporter operator pod is running
kubectl get po -n kube-system -l app.kubernetes.io/name=carbon-intensity-exporter

# get configmap data
kubectl get cm -n kube-system carbon-intensity -o jsonpath='{.data}' | jq
```

You can view the carbon intensity values with the following command.

```bash
# get carbon intensity binary data
kubectl get cm -n kube-system carbon-intensity -o jsonpath='{.binaryData.data}' | base64 --decode | jq
```

## Install Carbon Aware KEDA Operator

Currently KEDA is scaling your workload as needed and will scale up to a maximum of 100 replicas (KEDA's default) if needed. We will now add carbon awareness to it, so that it's maximum replicas is capped based on carbon intensity.

Install the latest version of the operator.

```bash
version=$(git describe --abbrev=0 --tags)
kubectl apply -f "https://github.com/Azure/carbon-aware-keda-operator/releases/download/${version}/carbonawarekedascaler-${version}.yaml"
```

> Latest release versions can be found here 👉 https://github.com/Azure/carbon-aware-keda-operator/releases/

With the operator installed, we can now deploy a custom resource called `CarbonAwareKedaScaler` to set the max replicas KEDA can scale up to based on carbon intensity.

```bash
kubectl apply -f - <<EOF
apiVersion: carbonaware.kubernetes.azure.com/v1alpha1 
kind: CarbonAwareKedaScaler 
metadata: 
  labels: 
    app.kubernetes.io/name: carbonawarekedascaler 
    app.kubernetes.io/instance: carbonawarekedascaler-sample 
    app.kubernetes.io/part-of: carbon-aware-keda-operator 
    app.kubernetes.io/managed-by: kustomize 
    app.kubernetes.io/created-by: carbon-aware-keda-operator 
  name: carbon-aware-word-processor-scaler
spec: 
  kedaTarget: scaledobjects.keda.sh 
  kedaTargetRef: 
    name: word-processor-scaler
    namespace: default 
  carbonIntensityForecastDataSource:       # carbon intensity forecast data source 
    mockCarbonForecast: false              # [OPTIONAL] use mock carbon forecast data 
    localConfigMap:                        # [OPTIONAL] use configmap for carbon forecast data 
      name: carbon-intensity 
      namespace: kube-system
      key: data 
  maxReplicasByCarbonIntensity:            # array of carbon intensity values in ascending order; each threshold value represents the upper limit and previous entry represents lower limit 
    - carbonIntensityThreshold: 200        # when carbon intensity is 437 or below 
      maxReplicas: 110                     # do more 
    - carbonIntensityThreshold: 260        # when carbon intensity is >437 and <=504 
      maxReplicas: 60 
    - carbonIntensityThreshold: 400        # when carbon intensity is >504 and <=571 (and beyond) 
      maxReplicas: 10                      # do less 
  ecoModeOff:                              # [OPTIONAL] settings to override carbon awareness; can override based on high intensity duration or schedules 
    maxReplicas: 100                       # when carbon awareness is disabled, use this value 
    carbonIntensityDuration:               # [OPTIONAL] disable carbon awareness when carbon intensity is high for this length of time 
      carbonIntensityThreshold: 555        # when carbon intensity is equal to or above this value, consider it high 
      overrideEcoAfterDurationInMins: 45   # if carbon intensity is high for this many hours disable ecomode 
    customSchedule:                        # [OPTIONAL] disable carbon awareness during specified time periods 
      - startTime: "2023-04-28T16:45:00Z"  # start time in UTC 
        endTime: "2023-04-28T17:00:59Z"    # end time in UTC 
    recurringSchedule:                     # [OPTIONAL] disable carbon awareness during specified recurring time periods 
      - "* 23 * * 1-5"                     # disable every weekday from 11pm to 12am UTC 
EOF
```

> IMPORTANT: If the Carbon Intensity Exporter Operator was NOT installed from the step above, make sure `mockCarbonForecast` is set to `true` to use mock data.

Check the status of the custom resource.

```bash
kubectl describe carbonawarekedascalers.carbonaware.kubernetes.azure.com carbon-aware-word-processor-scaler
```

Inspect operator logs.

```bash
kubectl logs -n carbon-aware-keda-operator-system -l control-plane=controller-manager
```

### Visualize Carbon Aware KEDA Operator

Inspecting operator logs and status/events of the custom resource is great. What's better? Visualizing the data in Grafana!

Each time the operator reconciles, it writes custom metrics (e.g., Carbon Intensity, Max Replicas, and Max Replicas) to the `/metrics` endpoint so that Prometheus can scape the data and visualized using Grafana.

This repo include manifests to deploy `kube-prometheus` into the cluster which is configured to scrape from the operator's namespace: `carbon-aware-keda-operator-system`.

Install the Prometheus operator.

```bash
kubectl apply --server-side -f hack/prometheus/manifests/setup
kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
```

Deploy `ServiceMonitor` into the cluster.

```bash
kubectl apply -f - <<EOF 
apiVersion: monitoring.coreos.com/v1  
kind: ServiceMonitor  
metadata:  
  labels:  
    app.kubernetes.io/component: metrics  
    app.kubernetes.io/created-by: carbon-aware-keda-operator  
    app.kubernetes.io/instance: controller-manager-metrics-monitor  
    app.kubernetes.io/managed-by: kustomize  
    app.kubernetes.io/name: servicemonitor  
    app.kubernetes.io/part-of: carbon-aware-keda-operator  
    control-plane: controller-manager  
  name: carbon-aware-keda-operator-controller-manager-metrics-monitor  
  namespace: carbon-aware-keda-operator-system  
spec:  
  endpoints:  
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token  
    path: /metrics  
    port: https  
    scheme: https  
    tlsConfig:  
      insecureSkipVerify: true  
  selector:  
    matchLabels:  
      control-plane: controller-manager 
EOF
```

Deploy the Prometheus + Grafana stack.

```bash
kubectl apply -f hack/prometheus/manifests/

# wait for all the monitoring pods to be running
kubectl get po -n monitoring -w
```

Assign the `carbon-aware-keda-operator-metrics-reader` cluster role to the Prometheus operator. This allows the Prometheus operator to scrape from the Carbon Aware KEDA Operator's namespace.

```bash
kubectl create clusterrolebinding carbon-aware-keda-operator-prometheus-rolebinding \
  --clusterrole=carbon-aware-keda-operator-metrics-reader \
  --serviceaccount=default:prometheus-operator
```

Grafana has been deployed as a service in the cluster; however, it is only accessible via `ClusterIP`. You can `port-forward` the service to access it from your local machine or you can update the service type to `LoadBalancer` so that you can reach it from outside the cluster.

```bash
kubectl patch svc grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
```

After a few minutes, Azure Load Balancer will provisioned and assigned a public IP. Browse to the website when it is fully provisioned.

```bash
echo "http://$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):3000/"
```

In your web browser, navigate to the Grafana URL which was obtained in the command above and log in using the default username `admin` with default password `admin`. You will be prompted to create a new password.

Download the sample dashboard [here](https://github.com/Azure/carbon-aware-keda-operator/blob/main/hack/grafana/Carbon%20Aware%20KEDA-Dashboard.json).

Expand the **Dashboards** menu item and click the **+ Import** button.

![grafana dashboard import](../assets/images/grafana-import.png)

Upload the **Carbon Aware KEDA-Dashboard.json** file and select **prometheus** as the data source then click Import.

![grafana dashboard datasource](../assets/images/grafana-dashboard.png)

You will be able to view the default max replicas, and the max replicas ceiling being raised and lowered over time based on the carbon intensity rating.

![carbon aware dashboard](../assets/images/carbon-aware-dashboard.png)

## Clean up

When you are done testing, delete the resources using the following command.

```bash
az group delete --resource-group $RESOURCE_GROUP
```

If you deployed the Azure resources using Terraform, you can run this command instead.

```bash
cd hack/azure/terraform
terraform destroy
```
