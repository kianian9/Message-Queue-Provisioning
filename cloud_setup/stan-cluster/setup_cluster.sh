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
    #kubectl apply -f stan_helm/gce_standard_storageclass.yaml
    kubectl apply -f stan_helm/gce_ssd_storageclass.yaml

    # Creating NATS namespace
    printf "\nCreating NATS Namespace\n"
    kubectl create namespace nats

    # Creating Prometheous Operator Deployment
    printf "\nInitializing Prometheous Operator Deployment\n"
    kubectl apply -f stan_helm/prometheus-operator-deployment.yaml -n nats

    printf "\nInitializing NATS Operator (1)\n"
    kubectl apply -f stan_helm/nats-operator1.yaml -n nats

    # TODO Wait for all pods to be done: kubectl get pods -n nats where nats-operator**** needs to be Running
    printf "\nInitializing NATS Operator (2)\n"
    kubectl apply -f stan_helm/nats-operator2.yaml -n nats

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

    printf "\nInitializing Prometheus Rules\n"
    kubectl apply -f stan_helm/prometheus-rbac.yaml -n nats

    printf "\nInitializing NATS Cluster\n"
    kubectl apply -f stan_helm/nats-cluster.yaml -n nats

    printf "\nInitializing Prometheus Operator\n"
    kubectl apply -f stan_helm/prometheus-operator.yaml -n nats

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

    printf "\nInitializing Prometheous Instance For NATS\n"
    kubectl apply -f stan_helm/prometheus-instance.yaml -n nats
   
    # Creating NATS Cluster through Helm Chart
    printf "\nInstalling NATS Cluster Through Helm Chart\n"
    helm install -f stan_helm/nats/values.yaml -n nats my-nats ./stan_helm/nats/

    # Waiting for NATS Instances to be in ready-state
    printf "\nWaiting for NATS Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep my-nats-2 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "3/3" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 2
        fi
    done

    # Creating STAN Cluster through Helm Chart
    printf "\nInstalling STAN Cluster Through Helm Chart\n"
    helm install -f stan_helm/stan/values.yaml -n nats my-stan ./stan_helm/stan/

    printf "\nWaiting for STAN Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep my-stan-2 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "2/2" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 2
        fi
    done
    
    # Creating Prometheus namespace
    printf "\nCreating Prometheus Namespace\n"
    kubectl create namespace prometheus
    
    # Setup Cluster Monitor
    printf "\nSetup Cluster Prometheous Monitor\n"
    helm install prometheus stable/prometheus-operator --namespace prometheus --set prometheusOperator.enabled=false > /dev/null 2>&1

    printf "\nSetups NATS Cluster LoadBalancer\n"
    kubectl apply -f stan_helm/lb.yaml -n nats

    # Creating Grafana Metric Visualizer
    printf "\nInitializing Grafana Visualizer for Prometheous\n"
    kubectl apply -f stan_helm/grafana.yaml -n nats

    # Setting Up Nginx Proxy For Grafana accesses
    printf "\nInitializing Nginx proxy For Grafana Access\n"
    kubectl apply -f stan_helm/nginx.yaml

    printf "\nWaiting For Load Balancing IP...\n"
    x=0
    while [ $x -le 0 ]
    do
        LB_IP=$(kubectl get services nats-lb -n nats --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
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


else
    printf "\n\nCould not create cluster!\n\n"
    exit 1
fi

printf "\nNATS LB IP: $LB_IP (client-port: 4222)\n"

printf "\nGrafana Node: $NodeName\n"
printf "Grafana For System Monitoring On 30000 (user: admin, password: prom-operator\n"
printf "Grafana For Message Queue Monitoring On 30001 (user/password: admin) \nwith Prometheus Operator ClusterIP: http://prometheus-operated:9090/\n"


printf "\n\nCluster successfully created!\n\n"

