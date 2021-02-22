#!/bin/bash
printf "\nWaiting for Prometheus Operator to become ready...\n"
x=0
READY="Running"
while [ $x -le 0 ]
do
    IS_READY=$(kubectl get pods -n nats | grep prometheus-operator 2>/dev/null)
    if [[ "$IS_READY" =~ "$READY" ]] && [[ "$IS_READY" =~ "0/1" ]]; then
        x=$(( $x + 1 ))
    else
        sleep 2
    fi
done