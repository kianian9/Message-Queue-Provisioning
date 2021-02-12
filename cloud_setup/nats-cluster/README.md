# RabbitMQ Cluster - GKE
Setups a RabbitMQ Cluster in GKE

## Setup Cluster
The **setup_cluster**-script creates a 3 worker node cluster (zonal) where each broker is run on a separate node.
Each node assigns a 3GB volume(standard HDD) for RabbitMQ persistent storaging.

## Destroy Cluster
The **destroy_cluster**-script destroys the GKE-cluster and removes all assigned disks.


## Parameters
In order to change the replication-factor in the cluster, change the amount of worker nodes.
Also change the replication for the RabbitMQ Cluster Instance (rabbit-instance.yaml).
Can also set to run with SSD instead of actual HDD.

The Installation follows the **RabbitMQ Cluster Operator guide**: https://www.rabbitmq.com/kubernetes/operator/operator-overview.html
