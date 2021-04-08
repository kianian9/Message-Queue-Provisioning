#!/bin/bash

usage() { echo "Usage: $0 [OPTIONAL] [-broker <string>] [-host <string>] [-port <string>] 
                                [-username <string>] [-password <string>] [-messageSize <int>] 
                                [-numMessages <int>] [-producers <int>] [-consumers <int>] 
                                [-queueType <string>] [-clusterID <string>] [-topic <string>]" 1>&2; exit 1; }

# Checking number arguments
if [[ $# -gt 22 ]]; then
    usage
fi
IMAGE_ARGUMENTS=""

while test $# -gt 0; do
    case "$1" in
            -broker)
                shift
                #BROKER=$1
                IMAGE_ARGUMENTS+=" -broker=$1"
                shift
                ;;
            -host)
                shift
                IMAGE_ARGUMENTS+=" -host=$1"
                shift
                ;;
            -port)
                shift
                IMAGE_ARGUMENTS+=" -port=$1"
                shift
                ;;
            -username)
                shift
                IMAGE_ARGUMENTS+=" -username=$1"
                shift
                ;;
            -password)
                shift
                IMAGE_ARGUMENTS+=" -password=$1"
                shift
                ;;
            -messageSize)
                shift
                IMAGE_ARGUMENTS+=" -messageSize=$1"
                shift
                ;;
            -numMessages)
                shift
                IMAGE_ARGUMENTS+=" -numMessages=$1"
                shift
                ;;
            -producers)
                shift
                IMAGE_ARGUMENTS+=" -producers=$1"
                shift
                ;;
            -consumers)
                shift
                IMAGE_ARGUMENTS+=" -consumers=$1"
                shift
                ;;
            -queueType)
                shift
                IMAGE_ARGUMENTS+=" -queueType=$1"
                shift
                ;;
            -clusterID)
                shift
                IMAGE_ARGUMENTS+=" -clusterID=$1"
                shift
                ;;
            -topic)
                shift
                IMAGE_ARGUMENTS+=" -topic=$1"
                shift
                ;;
            *)
            echo "$1 is not a recognized flag!"
            usage
            ;;
    esac
done

cd provisioning
CLIENT_IP=$(terraform output -raw client_host_ip)
cd ..
ssh -o StrictHostKeyChecking=no $CLIENT_IP "sudo docker run kianian9/masih $IMAGE_ARGUMENTS" >> results.txt