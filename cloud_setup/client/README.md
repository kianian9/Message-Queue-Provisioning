RabbitMQ Example:
    ./run_test.sh -broker rabbitmq -numMessages 14000000 -messageSize 500 -producers 3 -consumers 3 -host 35.228.198.185 -port 5672 -queueType QUORUM -username QsUiGAoH-mAp5EwRZGQvRKRDB54THQoo -password z9dm4yhNiWQ3CkX-62DXLg2AXMlJS4EF

STAN Example:
    ./run_test.sh -broker stan -numMessages 14000000 -messageSize 500 -producers 3 -consumers 3 -host 35.228.62.23 -port 4222 -clusterID stan -topic test

Kafka Example:
    ./run_test.sh -broker kafka -numMessages 14000000 -messageSize 500 -producers 3 -consumers 3 -host 35.228.85.208 -port 9094 -topic test

    sudo docker run kianian9/masih -broker=kafka -numMessages=2000000 -messageSize=1000 -producers=3 -consumers=3 -host=35.228.2.67 -port=9094 -topic=khalil_kelo