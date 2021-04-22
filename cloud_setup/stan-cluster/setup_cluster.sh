#!/bin/bash

start=`date +%s`
usage() { echo "Usage: $0 [-projectID <string>] [-nrNodes <int>] [-machineType <string>]" 1>&2; exit 1; }

function CHECK_NUMBER_NODES() {
    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] ; then
        echo "Error: nrNodes not given as a valid number!" >&2; exit 1
    fi
}

# Checking number arguments
if [[ $# -ne 6 ]]; then
    usage
fi

while test $# -gt 0; do
    case "$1" in
            -projectID)
                shift
                PROJECT_ID=$1
                shift
                ;;
            -nrNodes)
                shift
                NR_NODES=$1
                CHECK_NUMBER_NODES $NR_NODES
                if [[ $NR_NODES -le 0 ]] ; then
                    printf "Error: nrNodes must be greater than 0!\n" >&2; exit 1
                fi
                if [[ $NR_NODES -eq 1 ]] ; then
                    MIN_NODES=$NR_NODES
                else
                    MIN_NODES=$((NR_NODES-1))
                fi
                if [[ $NR_NODES -gt 2 ]] ; then
                    CLUSTERED="true"
                else
                    CLUSTERED="false"
                fi
                shift
                ;;
            -machineType)
                shift
                MACHINE_TYPE=$1
                shift
                ;;
            *)
            echo "$1 is not a recognized flag!"
            usage
            ;;
    esac
done

# Checking for valid project id
FOUND_PROJECT_ID=$(gcloud projects describe $PROJECT_ID 2>&1)
if [ $? -ne 0 ]; then
    printf "\nThe given project id wasn't found!\n">&2; exit 1
fi
gcloud config set project $PROJECT_ID

# Checking for valid machine type
VALID_MACHINE_TYPE=$(gcloud compute machine-types describe $MACHINE_TYPE 2>&1)
if [ $? -ne 0 ]; then
    printf "\nThe given machine type wasn't found!\n">&2; exit 1
fi

K8S_API_ENABLED=$(gcloud services list | grep container.googleapis.com)
# If Kubernetes API not enabled in the project then it will be enabled
if [[ ${#K8S_API_ENABLED} -eq 0 ]]; then
    gcloud services enable container.googleapis.com   
fi

cd provisioning
if ! terraform validate; then
    # Will initialize terraform files
    terraform init
fi

# Setups STAN K8s cluster
if terraform apply -var "project_id=$PROJECT_ID" -var "node_count=$NR_NODES" -var "machine_type=$MACHINE_TYPE" -auto-approve; then
    printf "\nInitializing local kubectl\n"
    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) \
        --region $(terraform output -raw zone)

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
    sleep 2
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep nats-operator 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "1/1" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 5
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
            sleep 5
        fi
    done

    printf "\nInitializing Prometheous Instance For NATS\n"
    kubectl apply -f stan_helm/prometheus-instance.yaml -n nats
   
    # Creating NATS Cluster through Helm Chart
    printf "\nInstalling NATS Cluster Through Helm Chart\n"
    cat stan_helm/nats/values.yaml | sed "s/NR_NODES/$NR_NODES/g" \
        | helm install -f - -n nats my-nats ./stan_helm/nats/

    # Waiting for NATS Instances to be in ready-state
    printf "\nWaiting for NATS Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep my-nats-$((NR_NODES-1)) 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "3/3" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 5
        fi
    done

    # Creating STAN Cluster through Helm Chart
    printf "\nInstalling STAN Cluster Through Helm Chart\n"
    cat stan_helm/stan/values.yaml | sed "s/NR_NODES/$NR_NODES/g; s/CLUSTERED/$CLUSTERED/g" \
        | helm install -f - -n nats my-stan ./stan_helm/stan/

    printf "\nWaiting for STAN Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods -n nats | grep my-stan-$((NR_NODES-1)) 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "2/2" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 5
        fi
    done

    # Setups STAN Cluster LoadBalancer
    printf "\nSetups NATS Cluster LoadBalancer\n"
    kubectl apply -f stan_helm/lb.yaml -n nats
    
    # Creating Prometheus namespace
    printf "\nCreating Prometheus Namespace\n"
    kubectl create namespace prometheus
    
    # Setup Cluster Monitor
    printf "\nSetup Cluster Prometheous Monitor\n"
    helm install prometheus stable/prometheus-operator --namespace prometheus \
        --set prometheusOperator.enabled=false > /dev/null 2>&1

    # Creating Grafana Metric Visualizer
    printf "\nInitializing Grafana Visualizer for Prometheous\n"
    kubectl apply -f stan_helm/grafana.yaml -n nats

    # Setting Up Grafana Services
    printf "\nSetting Up Grafana Services\n"
    kubectl apply -f stan_helm/grafana_service.yaml

    printf "\nWaiting For Load Balancing IP...\n"
    x=0
    while [ $x -le 0 ]
    do
        LB_IP=$(kubectl get services nats-lb -n nats --output \
                jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [[ ${#LB_IP} -gt 0 ]]; then
            x=$(( $x + 1 ))
        else
            sleep 2
        fi        
    done
else
    printf "\n\nCould not create cluster!\n\n"; exit 1
fi

printf "\nNATS LB IP: $LB_IP (client-port: 4222)\n"

NodeNames=$(kubectl get nodes --selector=kubernetes.io/role!=master -o \
    jsonpath={.items[*].status.addresses[?\(@.type==\"ExternalIP\"\)].address})
printf "\nGrafana Accessible From Nodes: $NodeNames\n"
printf "Grafana For System Monitoring On 30000 (user: admin, password: prom-operator)\n"
printf "Grafana For Message Queue Monitoring On 30001 (user/password: admin) \nwith Prometheus Operator ClusterIP: http://prometheus-operated:9090/\n"


end=`date +%s`
runtime=$( echo "$end - $start" | bc -l )

printf "\n\nCluster successfully created in: $runtime seconds!\n\n"

