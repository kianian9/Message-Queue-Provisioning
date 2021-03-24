#!/bin/bash

usage() { echo "Usage: $0 [-projectID <string>] [-machineType <string>]" 1>&2; exit 1; }

# Checking number arguments
if [[ $# -ne 4 ]]; then
    usage
fi

while test $# -gt 0; do
    case "$1" in
            -projectID)
                shift
                PROJECT_ID=$1
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
    echo $FOUND_PROJECT_ID
    printf "\nThe given project id wasn't found!\n">&2; exit 1
fi
gcloud config set project $PROJECT_ID

cd provisioning
if ! terraform validate; then
    # Will initialize terraform files
    terraform init
fi

# Setups client host
if terraform apply -var "project_id=$PROJECT_ID" -var "machine_type=$MACHINE_TYPE" -auto-approve; then
    printf "\n\nClient Host successfully created!\n\n" 
else
    printf "\n\nCould not create client host!\n\n"; exit 1
fi