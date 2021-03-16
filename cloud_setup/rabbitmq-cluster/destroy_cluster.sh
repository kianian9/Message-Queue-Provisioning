#!/bin/bash

gcloud config set project rabbitmq-9999

# Removing any external Load Balancers
FRONTEND=$(gcloud compute forwarding-rules list --format="value(name)")
for rule in $FRONTEND; do
    gcloud compute forwarding-rules delete $rule --quiet
    gcloud compute target-pools delete $rule --quiet
done

# Removing any added FW-rules
FW_RULES=$(gcloud compute firewall-rules list --format="value(name)")
RULE="k8s"
for rule in $FW_RULES; do
    if [[ "$rule" =~ "$RULE" ]]; then
        gcloud compute firewall-rules delete $rule --quiet
    fi
done

# Will destroy cluster and remove any disks in GCE
if ! terraform destroy -auto-approve; then
    printf "\n\nCluster could not be destroyed!\n\n"
    exit 1
else
    DISKS=$(gcloud compute disks list --format="value(name)")
    for disk in $DISKS; do
        gcloud compute disks delete $disk --quiet
    done
    printf "\n\nCluster successfully destroyed!\n\n"
fi

