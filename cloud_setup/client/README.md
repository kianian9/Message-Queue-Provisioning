# Client-node Setup In GCE
Creates a simple client that could be used for evaluating the message systems using Terraform & Ansible

## Setup Of Client
The **setup_client**-script takes 2 input arguments for being able to create a GCE instance.
The flags are:
* **-projectID**:  Unique id (string) that refers to the GCP project the client is intended to be deployed on
* **-machineType**: The GCE machine type the worker nodes will be assigned to
The client node is deployed in *europe-north1* region in zone *europe-north1-a*.

## Destruction Of Client
The **destroy_client**-script takes 1 argument for destroying the GCE instance. The flag is:
* **-broker**: The broker system that is going to be evaluated, supporting Kafka, RabbitMQ and STAN, where the default value is set to *RabbitMQ*
* **-host**: The host address for communicating with the broker system, default set to *localhost*
* **-port**: The port that is used by the broker system for handling incoming client-requests, default set to *5672* (RabbitMQ:s port by default)
* **-username**: An authorized RabbitMQ username that is used for creating queues,  by default set to *guest* (which only works with local brokers)
* **-password**: A RabbitMQ password (which corresponds to the username) that is used for creating queues, by default set to *guest*
* **-messageSize**: The size of each published message in bytes, by default set to publish *1000* bytes messages
* **-numMessages**: Total number of messages to publish by the publishers, by default set to publish *500 000* messages
* **-producers**: Total number of producers to use in the evaluation, by default set to *1* producer
* **-consumers**: Total number of consumers to use in the evaluation, by default set to *1* consumer
* **-queueType**: The queue type to use for the RabbitMQ system, supporting classic mirrored queues (CLASSIC) and quorum based queues *QUORUM* (which is used as default)
* **-clusterID**: The cluster id for the STAN brokers, set to *stan* as default
* **-topic**: The topic or subject to publish and consume from in Kafka and STAN, set to *test* as default

## Evaluation Framework
The client pulls the latest [Masih - Message Queue Benchmarking Tool](https://github.com/kianian9/Masih) that is used by the **run_test**-script for evaluating the system. The script takes up to 12 input argument, which are:
* **-projectID**:  Unique id (string) that refers to the GCP project the client is intended to be deployed on
* **-machineType**: The GCE machine type the worker nodes will be assigned to
