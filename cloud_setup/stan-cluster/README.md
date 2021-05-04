# NATS Streaming (STAN) Cluster Setup In GKE
Creates a STAN Kubernetes cluster using Helm charts

## Setup Of Cluster
The **setup_cluster**-script takes 3 input arguments for being able to create a STAN GKE cluster.
The flags are:
* **-projectID**:  Unique id (string) that refers to the GCP project the cluster is intended to be deployed on
* **-nrNodes**: Numerical value indicating the amount of worker nodes in the cluster
* **-machineType**: The GCE machine type the worker nodes will be assigned to

The setup assigns a 100 GiB (Gibibytes) SSD for each broker for persisting data on. The worker nodes are deployed in *europe-north1* region in zone *europe-north1-a*.

## Destruction Of Cluster
The **destroy_cluster**-script takes 1 argument for destroying the GKE-cluster and removing all assigned disks. The flag is:
* **-projectID**:  Unique id (string) referring to the GCP project the cluster has been created on and will be removed from
