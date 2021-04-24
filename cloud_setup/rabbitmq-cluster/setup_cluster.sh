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
                MIRRORS=$(($NR_NODES / 2 +1))
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

# Setups RabbitMQ K8s cluster
if terraform apply -var "project_id=$PROJECT_ID" -var "node_count=$NR_NODES" -var "machine_type=$MACHINE_TYPE" -auto-approve; then
    printf "\nInitializing local kubectl\n"
    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) \
        --region $(terraform output -raw zone)
    
    # Setups persistent storage class (CSI Driver)
    printf "\nCreating storage class (CSI-Driver)\n"
    #kubectl apply -f rabbitmq/gce_standard_storageclass.yaml
    kubectl apply -f rabbitmq/gce_ssd_storageclass.yaml

    # Installs RabbitMQ Cluster Operator (version v1.4.0 latest at the moment) NOTE: Preset to operate in rabbitmq-system ns
    printf "\nInstalling RabbitMQ Cluster Operator\n"
    kubectl apply -f rabbitmq/cluster-operator.yml

    # Creating RabbitMQ Instances(Brokers)
    printf "\nInitializing RabbitMQ Instance(s)\n"
    cat rabbitmq/rabbit-instance.yaml | sed "s/NR_NODES/$NR_NODES/g" \
        | kubectl apply -f - -n rabbitmq-system
    
    # Waiting for RabbitMQ Instances to be in ready-state
    printf "\nWaiting for Instance(s) to become ready...\n"
    x=0
    READY="Running"
    while [ $x -le 0 ]
    do
        IS_READY=$(kubectl get pods rabbitmq-server-$((NR_NODES-1)) -n rabbitmq-system -o \
                    jsonpath="Status: {.status.phase}" 2>/dev/null)
        if [[ "$IS_READY" =~ "$READY" ]]; then
            x=$(( $x + 1 ))
        else
            sleep 5
        fi        
    done

    # Setups RabbitMQ Cluster LoadBalancer
    printf "\nSetups RabbitMQ Cluster LoadBalancer\n"
    kubectl apply -f rabbitmq/rabbit_lb.yaml -n rabbitmq-system

    # Creating Prometheous Operator
    printf "\nInitializing Prometheous Operator\n"
    kubectl apply -f rabbitmq/prometheus-operator-deployment.yaml -n rabbitmq-system

    # Creating Prometheus Roles
    printf "\nSetup Prometheous Roles\n"
    kubectl apply -f rabbitmq/prometheus-roles.yaml -n rabbitmq-system

    # Creating Prometheous Instance For RabbitMQ
    printf "\nInitializing Prometheous Instance For RabbitMQ\n"
    kubectl apply -f rabbitmq/prometheus.yaml -n rabbitmq-system

    # Creating Prometheous Pod Monitor
    printf "\nInitializing Prometheous Pod Monitor\n"
    kubectl apply -f rabbitmq/rabbitmq-pod-monitor.yaml -n rabbitmq-system

    # Creating Prometheus Namespace
    printf "\nCreating Prometheous Namespace\n"
    kubectl create namespace prometheus

    # Installing Cluster Prometheus Monitor
    printf "\nSetup Cluster Prometheous Monitor\n"
    helm install prometheus stable/prometheus-operator --namespace prometheus \
        --set prometheusOperator.enabled=false > /dev/null 2>&1

    # Creating Grafana Metric Visualizer
    printf "\nInitializing Grafana Visualizer for Prometheous\n"
    kubectl apply -f rabbitmq/grafana.yaml -n rabbitmq-system

    # Setting Up Grafana Services
    printf "\nSetting Up Grafana Services\n"
    kubectl apply -f rabbitmq/grafana_service.yaml
    
    # Setting High-Availability Policies For RabbitMQ
    printf "\nSetting High-Availability Policies For RabbitMQ\n"
    kubectl exec -it rabbitmq-server-0 -n rabbitmq-system -- /bin/bash -c "rabbitmqctl set_policy ha-mirror \".*\" '{\"ha-mode\":\"exactly\",\"ha-params\":$MIRRORS}'"

    printf "\nWaiting For Load Balancing IP...\n"
    x=0
    while [ $x -le 0 ]
    do
        LB_IP=$(kubectl get services rabbit-http-lb -n rabbitmq-system \
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
printf "\nRabbitMQ LB IP: $LB_IP (ports 5672 and 15672)\n"
instance=rabbitmq
username=$(kubectl get secret ${instance}-default-user -n rabbitmq-system -o jsonpath="{.data.username}" | base64 --decode)
password=$(kubectl get secret ${instance}-default-user -n rabbitmq-system -o jsonpath="{.data.password}" | base64 --decode)
printf "RabbitMQ Management Username: $username\n"
printf "RabbitMQ Management Password: $password\n"

NodeNames=$(kubectl get nodes --selector=kubernetes.io/role!=master -o \
    jsonpath={.items[*].status.addresses[?\(@.type==\"ExternalIP\"\)].address})
printf "\nGrafana Accessible From Nodes: $NodeNames\n"
printf "Grafana For System Monitoring On 30000 (user: admin, password: prom-operator)\n"
printf "Grafana For Message Queue Monitoring On 30001 (user/password: admin) \nwith Prometheus Operator ClusterIP: http://prometheus-operated:9090/\n"


end=`date +%s`
runtime=$( echo "$end - $start" | bc -l )

printf "\n\nCluster successfully created in: $runtime seconds!\n\n"

