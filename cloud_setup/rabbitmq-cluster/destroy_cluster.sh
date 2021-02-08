#!/bin/bash

# Will destroy cluster
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




