#!/bin/bash

gcloud config set project rabbitmq-9999
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
    kubectl apply -f rabbitmq/gce_standard_storageclass.yaml
    #kubectl apply -f rabbitmq/gce_ssd_storageclass.yaml

    # Installs RabbitMQ Cluster Operator (version v1.4.0 latest at the moment)
    printf "\nInstalling RabbitMQ Cluster Operator\n"
    kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/download/v1.4.0/cluster-operator.yml"
    #kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"

    # Creating RabbitMQ Instances(Brokers)
    printf "\nInitializing RabbitMQ Instance(s)\n"
    kubectl apply -f rabbitmq/rabbit-instance.yaml
    
    # Waiting for RabbitMQ Instances to be in ready-state
    printf "Waiting for Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods rabbitmq-server-2 -o jsonpath="Status: {.status.phase}" 2>/dev/null)

        if [[ "$IS_READY" =~ "$READY" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 5
        fi        
    done

    # Setups RabbitMQ Cluster LoadBalancer
    printf "\nSetups RabbitMQ Cluster LoadBalancer\n"
    kubectl apply -f rabbitmq/rabbit_lb.yaml

    # Creating Prometheous Operator
    printf "\nInitializing Prometheous Operator\n"
    kubectl apply -f rabbitmq/prometheus-operator-deployment.yaml

    # Creating Prometheus Roles
    printf "\nSetup Prometheous Roles\n"
    kubectl apply -f rabbitmq/prometheus-roles.yaml

    # Creating Prometheous Instance For RabbitMQ
    printf "\nInitializing Prometheous Instance For RabbitMQ\n"
    kubectl apply -f rabbitmq/prometheus.yaml

    # Creating Prometheous Pod Monitor
    printf "\nInitializing Prometheous Pod Monitor\n"
    kubectl apply -f rabbitmq/rabbitmq-pod-monitor.yaml

    # Creating Prometheus Namespace
    printf "\nCreating Prometheous Namespace\n"
    kubectl create namespace prometheus

    # Installing Cluster Prometheus Monitor
    printf "\nSetup Cluster Prometheous Monitor\n"
    helm install prometheus stable/prometheus-operator --namespace prometheus --set prometheusOperator.enabled=false > /dev/null 2>&1

    # Creating Grafana Metric Visualizer
    printf "\nInitializing Grafana Visualizer for Prometheous\n"
    kubectl apply -f rabbitmq/grafana.yaml

    # Setting Up Nginx Proxy For Grafana accesses
    printf "\nInitializing Nginx proxy For Grafana Access\n"
    kubectl apply -f rabbitmq/nginx.yaml

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
printf "\nRabbitMQ LB IP: $LB_IP (ports 5672 and 15672)\n"
instance=rabbitmq
username=$(kubectl get secret ${instance}-default-user -o jsonpath="{.data.username}" | base64 --decode)
password=$(kubectl get secret ${instance}-default-user -o jsonpath="{.data.password}" | base64 --decode)
printf "RabbitMQ Management Username: $username\n"
printf "RabbitMQ Management Password: $password\n"

printf "\nGrafana Node: $NodeName\n"
printf "Grafana For System Monitoring On 30000 (user: admin, password: prom-operator\n"
printf "Grafana For Message Queue Monitoring On 30001 (user/password: admin) \nwith Prometheus Operator ClusterIP: http://prometheus-operated:9090/\n"

#printf "Grafana NodePort: 30009 with Prometheus Operator ClusterIP: http://prometheus-operated:9090/\n"

printf "\n\nCluster successfully created!\n\n"

