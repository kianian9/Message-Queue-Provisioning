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

# Setups Kafka K8s cluster
if terraform apply -var "project_id=$PROJECT_ID" -var "node_count=$NR_NODES" -var "machine_type=$MACHINE_TYPE" -auto-approve; then
    printf "\nInitializing local kubectl\n"
    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) \
        --region $(terraform output -raw zone)

    # Setups persistent storage class (CSI Driver)
    printf "\nCreating storage class (CSI-Driver)\n"
    #kubectl apply -f kafka/gce_standard_storageclass.yaml
    kubectl apply -f kafka/gce_ssd_storageclass.yaml

    # Creating Kafka Namespace (recommended and didn't work on default-NS)
    printf "\nCreating Kafka Namespace\n"
    kubectl create namespace kafka

    # Installs Strimzi Kafka Cluster Operator (version v0.21.1 latest at the moment)
    printf "\nInstalling Strimzi Kafka Cluster Operator\n"
    cat kafka/strimzi-cluster-operator-0.21.1.yaml | sed 's/namespace: .*/namespace: kafka/' \
        | kubectl apply -f - -n kafka

    # Creating Kafka Instances(Brokers)
    printf "\nInitializing Kafka Instance(s)\n"
    #kubectl apply -f kafka/kafka-instance.yaml -n kafka
    cat kafka/kafka-instance.yaml | sed "s/NR_NODES/$NR_NODES/g; s/MIN_NODES/$MIN_NODES/g" \
        | kubectl apply -f - -n kafka

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

    # Creating Prometheous Instance For Kafka
    printf "\nInitializing Prometheous Instance For Kafka\n"
    kubectl apply -f kafka/prometheus.yaml -n kafka

    # Creating Prometheus Namespace
    printf "\nCreating Prometheous Namespace\n"
    kubectl create namespace prometheus

    # Installing Cluster Prometheus Monitor
    printf "\nSetup Cluster Prometheous Monitor\n"
    helm install prometheus stable/prometheus-operator --namespace prometheus \
        --set prometheusOperator.enabled=false > /dev/null 2>&1

    # Creating Grafana Metric Visualizer
    printf "\nInitializing Grafana Visualizer for Prometheous\n"
    kubectl apply -f kafka/grafana.yaml -n kafka

    # Setting Up Grafana Services
    printf "\nSetting Up Grafana Services\n"
    kubectl apply -f kafka/grafana_service.yaml

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
        LB_IP=$(kubectl get services kafka-cluster-kafka-external-bootstrap --namespace kafka \
            --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
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

printf "\nKafka LB IP: $LB_IP (external port 9094)\n"

NodeNames=$(kubectl get nodes --selector=kubernetes.io/role!=master -o \
    jsonpath={.items[*].status.addresses[?\(@.type==\"ExternalIP\"\)].address})
printf "\nGrafana Accessible From Nodes: $NodeNames\n"
printf "Grafana For System Monitoring On 30000 (user: admin, password: prom-operator)\n"
printf "Grafana For Message Queue Monitoring On 30001 (user/password: admin) \nwith Prometheus Operator ClusterIP: http://prometheus-operated:9090/\n"


end=`date +%s`
runtime=$( echo "$end - $start" | bc -l )

printf "\n\nCluster successfully created in: $runtime seconds!\n\n"

