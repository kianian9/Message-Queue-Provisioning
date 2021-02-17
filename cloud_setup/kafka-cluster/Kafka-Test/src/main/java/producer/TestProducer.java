package producer;


import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.util.Properties;

public class TestProducer {

    public static void main(String[] args) throws InterruptedException {
        Properties props = new Properties();
        props.put("bootstrap.servers", "35.228.181.254:9094");
        props.put("acks", "all");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.setProperty("partition.assignment.strategy", "org.apache.kafka.clients.consumer.RoundRobinAssignor");

        Producer<String, String> producer = new KafkaProducer<>(props);
        int i = 0;
        while (true) {
            producer.send(new ProducerRecord<>("kian", Integer.toString(i), Integer.toString(i)));
            Thread.sleep(100);
            i++;
            System.out.println("Sent message: " + i);
        }
        /*for (int i = 0; i < 100; i++) {
            producer.send(new ProducerRecord<>("kian", Integer.toString(i), Integer.toString(i)));
            Thread.sleep(100);
        }



        Thread.sleep(1000);
        producer.close();
        */
    }

}
