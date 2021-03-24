#!/bin/bash

usage() { echo "Usage: $0 [-projectID <string>]" 1>&2; exit 1; }

# Checking number arguments
if [[ $# -ne 2 ]]; then
    usage
fi

while test $# -gt 0; do
    case "$1" in
            -projectID)
                shift
                PROJECT_ID=$1
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

cd provisioning
# Will destroy cluster and remove any added disks in GCE
if ! terraform destroy -var "project_id=" -var "node_count=" -var "machine_type=" -auto-approve; then
    printf "\n\nCluster could not be destroyed!\n\n"; exit 1
else
    DISKS=$(gcloud compute disks list --format="value(name)")
    for disk in $DISKS; do
        gcloud compute disks delete $disk --quiet
    done
    printf "\n\nCluster successfully destroyed!\n\n"
fi

