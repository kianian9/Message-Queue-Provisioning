#!/bin/bash

gcloud config set project nats-9999
if ! terraform validate; then
    # Will initialize terraform files
    terraform init
fi

# Setups NATS K8s cluster
if terraform apply -auto-approve; then
    printf "\nInitializing local kubectl\n"
    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw zone)

    # Setups persistent storage class (CSI Driver)
    printf "\nCreating storage class (CSI-Driver)\n"
    kubectl apply -f stan/gce_standard_storageclass.yaml
    #kubectl apply -f stan/gce_ssd_storageclass.yaml


    # Creating NATS namespace
    kubectl create namespace nats
    printf "\nCreating NATS Namespace\n"

    # TODO Wait for all pods to be done: kubectl get pods -n nats where nats-2 needs to be Running
    printf "\nCreating NATS Cluster\n"
    kubectl apply -f stan/nats-instance.yaml -n nats

    # Waiting for NATS Instances to be in ready-state
    printf "\nWaiting for NATS Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep nats-2 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "1/1" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 2
        fi
    done

    # TODO Wait for all pods to be done: kubectl get pods -n nats where stan-2 needs to be Running
    printf "\nCreating STAN (NATS Streaming) Cluster\n"
    kubectl apply -f stan/stan-instance.yaml -n nats

    # Waiting for NATS Instances to be in ready-state
    printf "\nWaiting for STAN Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep stan-2 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "1/1" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 2
        fi
    done

    printf "\nInitializing NATS Operator (1)\n"
    kubectl apply -f stan/nats-operator1.yaml -n nats

    # TODO Wait for all pods to be done: kubectl get pods -n nats where nats-operator**** needs to be Running
    printf "\nInitializing NATS Operator (2)\n"
    kubectl apply -f stan/nats-operator2.yaml -n nats

    printf "\nWaiting for NATS Operator to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep nats-operator 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "1/1" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 2
        fi
    done

    # TODO Wait for all pods to be done: kubectl get pods -n nats where prometheus-operator*** needs to be Running
    printf "\nInitializing Prometheus Operator\n"
    kubectl apply -f stan/prometheus-operator.yaml -n nats

    printf "\nWaiting for Prometheus Operator to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep prometheus-operator 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "1/1" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 2
        fi
    done

    printf "\nInitializing NATS Cluster\n"
    kubectl apply -f stan/nats-cluster.yaml -n nats

    printf "\nInitializing Prometheus Rules\n"
    kubectl apply -f stan/prometheus-rbac.yaml -n nats

    printf "\nInitializing Prometheous Instance For NATS\n"
    kubectl apply -f stan/prometheus-instance.yaml -n nats

    printf "\nSetup Prometheous ServiceMonitor For NATS\n"
    kubectl apply -f stan/service-monitor.yaml -n nats

    printf "\nSetups NATS Cluster LoadBalancer\n"
    kubectl apply -f stan/nats_lb.yaml -n nats

    printf "\nCreating Prometheus Namespace\n"
    kubectl create namespace prometheus

    printf "\nSetup Cluster Prometheous Monitor\n"
    helm install prometheus stable/prometheus-operator --namespace prometheus --set prometheusOperator.enabled=false > /dev/null 2>&1

    # Creating Grafana Metric Visualizer
    printf "\nInitializing Grafana Visualizer for Prometheous\n"
    kubectl apply -f stan/grafana.yaml -n nats

    # Setting Up Nginx Proxy For Grafana accesses
    printf "\nInitializing Nginx proxy For Grafana Access\n"
    kubectl apply -f stan/nginx.yaml

    printf "\nWaiting For Load Balancing IP...\n"
    x=0
    while [ $x -le 0 ]
    do
        LB_IP=$(kubectl get services nats-http-lb -n nats --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
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
            sleep 2
        fi
    done
    

    # ADDED
    #kubectl create namespace prometheus
    #helm install prometheus stable/prometheus-operator --namespace prometheus --set prometheusOperator.enabled=false > /dev/null 2>&1

else
    printf "\n\nCould not create cluster!\n\n"
    exit 1
fi

printf "\nNATS LB IP: $LB_IP (client-port: 4222)\n"

printf "\nGrafana Node: $NodeName\n"
printf "Grafana For System Monitoring On 30000 (user: admin, password: prom-operator\n"
printf "Grafana For Message Queue Monitoring On 30001 (user/password: admin) \nwith Prometheus Operator ClusterIP: http://prometheus-operated:9090/\n"
printf "NATS Prometheus Collectioner On 30002\n"


printf "\n\nCluster successfully created!\n\n"

