#!/bin/bash

if ! terraform validate; then
    # Will initialize terraform files
    terraform init
fi

# Setups rabbimq K8s cluster
if terraform apply -auto-approve; then
    printf "\nInitializing local kubectl\n"
    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw zone)
    # Setups standard persistent storage class
    kubectl apply -f rabbitmq/gce_standard_storageclass.yaml
    #kubectl apply -f rabbitmq/gce_ssd_storageclass.yaml

    # Installs RabbitMQ Cluster Operator (version v1.4.0 latest at the moment)
    printf "\nInstalling RabbitMQ Cluster Operator\n"
    kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/download/v1.4.0/cluster-operator.yml"
    #kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"

    # Creating RabbitMQ Instances(Brokers)
    printf "\nInitializing RabbitMQ Instance(s)\n"
    kubectl apply -f rabbitmq/rabbit-instance.yaml

    # Waiting some time for instances to create
    #printf "Creating...\n"
    #sleep 30

    # Waiting for RabbitMQ Instances to be in ready-state
    #printf "\nWaiting for Instance(s) to become ready\n"
    #kubectl wait --for=condition=Ready pod/rabbitmq-server-0 pod/rabbitmq-server-1 pod/rabbitmq-server-2 --timeout 30m
    
    # Waiting for RabbitMQ Instances to be in ready-state
    printf "Waiting for Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        #IS_DONE=$(kubectl wait --for=condition=Ready pod/rabbitmq-server-0 pod/rabbitmq-server-1 pod/rabbitmq-server-2)
        IS_READY=$(kubectl get pods rabbitmq-server-2 -o jsonpath="Status: {.status.phase}" 2>/dev/null)

        if [[ "$IS_READY" =~ "$READY" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 5
        fi        
        #if echo "$IS_DONE" | grep -q "$ALL_PODS_READY_COND"; then
        #    x=$(( $x + 1 ))
        #else
        #    sleep 5
        #fi
    done

    # Setups RabbitMQ Cluster LoadBalancer
    printf "\nSetups RabbitMQ Cluster LoadBalancer\n"
    kubectl apply -f rabbitmq/rabbit_lb.yaml
    printf "Waiting For Load Balancing IP...\n"
    x=0
    while [ $x -le 0 ]
    do
        LB_IP=$(kubectl get services rabbit-http-lb --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
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
printf "RabbitMQ LB IP: $LB_IP (ports 5672 and 15672)\n"
instance=rabbitmq
username=$(kubectl get secret ${instance}-default-user -o jsonpath="{.data.username}" | base64 --decode)
password=$(kubectl get secret ${instance}-default-user -o jsonpath="{.data.password}" | base64 --decode)
printf "RabbitMQ Management Username:$username\n"
printf "RabbitMQ Management Password:$password\n"

printf "\n\nCluster successfully created!\n\n"

