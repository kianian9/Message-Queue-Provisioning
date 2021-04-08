package producer;


import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Properties;

public class TestProducer {

    public static void main(String[] args) throws InterruptedException {
        String ip = null;
        String topic = null;
        int numMessages = 0;
        if (args.length == 3) {
            ip = args[0];
            System.out.println(ip);
            try {
                numMessages = Integer.parseInt(args[1]);
            } catch (NumberFormatException e) {
                System.err.println(e.getMessage());
                System.exit(1);
            }
            topic = args[2];
        } else {
            System.err.println("Usage: [IP]<string> [NUM_MESSAGES]<int> [TOPIC]<string>");
            System.exit(1);
        }
        //String ip = "35.228.2.67";
        Properties props = new Properties();
        props.put("bootstrap.servers", ip+":9094");
        props.put("acks", "all");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.setProperty("partition.assignment.strategy", "org.apache.kafka.clients.consumer.RoundRobinAssignor");

        Producer<String, String> producer = new KafkaProducer<>(props);
        int i = 0;
        long timestamp1 = System.currentTimeMillis();
        int nrMessages = 0;
        char[] a = new char[1000];
        char[] b = new char[12];
        byte[] c = new byte[1000];
        byte[] myvar = "Any String you want".getBytes();


        for (int j = 0; j < numMessages; j++) {
            long timestamp2 = System.currentTimeMillis();
            String message = "Test - " + i;
            String s = new String(c, StandardCharsets.UTF_8);
            producer.send(new ProducerRecord<>("kian-subject", Integer.toString(i), s));
            i++;
            long time = (timestamp2 - timestamp1) / 1000;
            if (time >= 1) {
                System.out.println("Pub msgs per sec (approx): " + (i - nrMessages));
                nrMessages = i;
                timestamp1 = timestamp2;
            }
        }

        /*
        while (true) {
            long timestamp2 = System.currentTimeMillis();
            String message = "Test - " + i;
            producer.send(new ProducerRecord<>("kian-subject", Integer.toString(i), message));
            i++;
            long time = (timestamp2 - timestamp1) / 1000;
            if (time >= 1) {
                System.out.println("Pub msgs per sec (approx): " + (i - nrMessages));
                nrMessages = i;
                timestamp1 = timestamp2;
            }
            //System.out.println("Sent message: " + message);
        }

        */
        /*for (int i = 0; i < 100; i++) {
            producer.send(new ProducerRecord<>("kian", Integer.toString(i), Integer.toString(i)));
            Thread.sleep(100);
        }



        Thread.sleep(1000);
        producer.close();
        */
    }

}
