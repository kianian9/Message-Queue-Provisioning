RabbitMQ Example:
    ./run_test.sh -broker rabbitmq -numMessages 1000000 -messageSize 1000 -producers 1 -consumers 1 -host 35.228.198.185 -port 5672 -username QsUiGAoH-mAp5EwRZGQvRKRDB54THQoo -password z9dm4yhNiWQ3CkX-62DXLg2AXMlJS4EF

STAN Example:
    ./run_test.sh -broker stan -numMessages 5000000 -messageSize 1000 -producers 1 -consumers 1 -host 35.228.62.23 -port 4222 -clusterID stan -topic kian

Kafka Example:
    ./run_test.sh -broker kafka -numMessages 5000000 -messageSize 1000 -producers 3 -consumers 3 -host 35.228.2.67 -port 9094 -topic khalil_kelo