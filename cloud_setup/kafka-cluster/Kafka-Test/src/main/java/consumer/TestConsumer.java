package consumer;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

public class TestConsumer {

    public static void main(String[] args) throws InterruptedException {
        Properties props = new Properties();
        props.setProperty("bootstrap.servers", "35.228.181.254:9094");
        props.setProperty("group.id", "test2");
        props.setProperty("enable.auto.commit", "true");
        props.setProperty("auto.commit.interval.ms", "100");
        props.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.setProperty("partition.assignment.strategy", "org.apache.kafka.clients.consumer.RoundRobinAssignor");
        KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
        consumer.subscribe(Collections.singletonList("kian"));

        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(10));
            for (ConsumerRecord<String, String> record : records)
                System.out.printf("offset = %d, key = %s, value = %s%n", record.offset(), record.key(), record.value());
            Thread.sleep(1000);
        }
    }

}
