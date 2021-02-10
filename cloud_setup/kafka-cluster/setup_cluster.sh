#!/bin/bash

gcloud config set project kafka-304409
if ! terraform validate; then
    # Will initialize terraform files
    terraform init
fi

# Setups rabbimq K8s cluster
if terraform apply -auto-approve; then
    printf "\nInitializing local kubectl\n"
    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw zone)

    # Setups persistent storage class (CSI Driver)
    printf "\nCreating storage class (CSI-Driver)\n"
    kubectl apply -f kafka/gce_standard_storageclass.yaml
    #kubectl apply -f rabbitmq/gce_ssd_storageclass.yaml

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
    kubectl apply -f kafka/kafka-instance.yaml --namespace kafka

    # Waiting for Kafka Instances to be in ready-state
    printf "Waiting for Instance(s) to become ready...\n"
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

    # Setups Kafka Cluster LoadBalancer
    printf "\nWaiting For Load Balancing IP...\n"
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
else
    printf "\n\nCould not create cluster!\n\n"
    exit 1
fi

printf "Kafka LB IP: $LB_IP (external port 9094)\n"

printf "\n\nCluster successfully created!\n\n"

