#  Message Queue Provisioning
This repository can be used for provisioning GKE clusters using Terraform with message queue deployments. A client that is provisioned with Terraform and configured through Ansible for evaluate the systems from is also available. 
## Installation
In order to successfully configure the systems, a few software prerequisites are needed:
* **Bash**: The setup consist of a bash script that performs all installation steps
* **Terraform** (Tested on v0.14): The GKE clusters are provisioned using Terraform
* **Ansible** (Tested on v2.9.16): The GCE (client-node) instance is configured using Ansible
* **gcloud** (Tested on v326.0.0): The Google Cloud SDK CLI for communicating with the GCP
* **kubectl** (Tested on v.1.19.2):Kubernetes command-line tool for interacting with the clusters
* **Helm** (Tested on v.3.5.2): Package manager for Kubernetes needed for monitoring & NATS setup


## Execution
Each message queue system have its own setup-script that orchestrates the installation procedure, more about the installation can be found in the corresponding systems.
