#!/bin/bash

gcloud config set project kafka-304409
if ! terraform validate; then
    # Will initialize terraform files
    terraform init
fi

# Setups Kafka K8s cluster
if terraform apply -auto-approve; then
    printf "\nInitializing local kubectl\n"
    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw zone)

    # Setups persistent storage class (CSI Driver)
    printf "\nCreating storage class (CSI-Driver)\n"
    #kubectl apply -f kafka/gce_standard_storageclass.yaml
    kubectl apply -f kafka/gce_ssd_storageclass.yaml

    # Creating Kafka Namespace (recommended and didn't work on default-NS)
    printf "\nCreating Kafka Namespace\n"
    kubectl create namespace kafka

    # Installs Strimzi Kafka Cluster Operator (version v0.21.1 latest at the moment)
    printf "\nInstalling Strimzi Kafka Cluster Operator\n"
    curl -L https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.21.1/strimzi-cluster-operator-0.21.1.yaml \
        | sed 's/namespace: .*/namespace: kafka/' \
        | kubectl apply -f - -n kafka

    # Creating Kafka Instances(Brokers)
    printf "\nInitializing Kafka Instance(s)\n"
    kubectl apply -f kafka/kafka-instance.yaml -n kafka

    # Creating Prometheous Operator
    printf "\nInitializing Prometheous Operator\n"
    kubectl apply -f kafka/prometheus-operator-deployment.yaml -n kafka

    # Creating Prometheous Additional
    printf "\nSetup Prometheous Additional Settings\n"
    kubectl apply -f kafka/prometheus-additional.yaml -n kafka

    # Creating Prometheous Pod Monitor
    printf "\nInitializing Prometheous Pod Monitor\n"
    kubectl apply -f kafka/strimzi-pod-monitor.yaml -n kafka

    # Creating Prometheous Rules
    printf "\nInitializing Prometheous Rules\n"
    kubectl apply -f kafka/prometheus-rules.yaml -n kafka

    # Creating Prometheous Prometheous Instance For Kafka
    printf "\nInitializing Prometheous Instance For Kafka\n"
    kubectl apply -f kafka/prometheus.yaml -n kafka

    # Creating Prometheus Namespace
    printf "\nCreating Prometheous Namespace\n"
    kubectl create namespace prometheus

    # Installing Cluster Prometheus Monitor
    printf "\nSetup Cluster Prometheous Monitor\n"
    helm install prometheus stable/prometheus-operator --namespace prometheus --set prometheusOperator.enabled=false > /dev/null 2>&1

    # Creating Grafana Metric Visualizer
    printf "\nInitializing Grafana Visualizer for Prometheous\n"
    kubectl apply -f kafka/grafana.yaml -n kafka

    # Setting Up Nginx Proxy For Grafana accesses
    printf "\nInitializing Nginx proxy For Grafana Access\n"
    kubectl apply -f kafka/nginx.yaml

    sleep 2
    # Waiting for Kafka Instances to be in ready-state
    printf "\nWaiting for Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods --namespace=kafka | grep kafka-cluster-entity-operator 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 5
        fi
    done

    # Waits For Kafka Cluster LoadBalancer
    printf "\nWaiting For Kafka Load Balancing IP...\n"
    x=0
    while [ $x -le 0 ]
    do
        LB_IP=$(kubectl get services kafka-cluster-kafka-external-bootstrap --namespace kafka --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [[ ${#LB_IP} -gt 0 ]]; then
            x=$(( $x + 1 ))
        else
            sleep 2
        fi        
    done

    # Waiting for Nginx to be in ready-state
    printf "\nWaiting for Nginx to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pod -l app=nginx | grep Running 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]]; then
            PodName=$(kubectl get pod -l app=nginx -o jsonpath="{.items[0].metadata.name}")
            NodeName=$(kubectl get pods $PodName -o wide --output jsonpath='{.spec.nodeName}')
            x=$(( $x + 1 ))
        else
            sleep 5
        fi
    done
else
    printf "\n\nCould not create cluster!\n\n"
    exit 1
fi

printf "\nKafka LB IP: $LB_IP (external port 9094)\n"
#printf "Grafana LB IP: $GRAFANA_LB_IP (external port 3000)\n"

printf "Grafana Node: $NodeName\n"
printf "Grafana For System Monitoring On 30000 (user: admin, password: prom-operator\n"
printf "Grafana For Message Queue Monitoring On 30001 (user/password: admin) \nwith Prometheus Operator ClusterIP: http://prometheus-operated:9090/\n"





printf "\n\nCluster successfully created!\n\n"

