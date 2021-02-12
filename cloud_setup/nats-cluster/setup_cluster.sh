#!/bin/bash

gcloud config set project nats-9999
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
    kubectl apply -f stan/gce_standard_storageclass.yaml
    #kubectl apply -f stan/gce_ssd_storageclass.yaml


else
    printf "\n\nCould not create cluster!\n\n"
    exit 1
fi


printf "\n\nCluster successfully created!\n\n"

