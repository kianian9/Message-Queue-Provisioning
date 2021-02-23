package consumer;

import com.rabbitmq.client.*;

import java.util.HashMap;
import java.util.Map;


public class RabbitConsumer {

    private static final String TASK_QUEUE_NAME = "task_queue";
    private static String RABBIT_HOST = "35.228.201.31";
    private static String RABBIT_USER = "FOfpGF5xwneOnVP_jXB00XSqo0QaxeSh";
    private static String RABBIT_PASSWORD = "gC0ylHgwBlrOEdDldyEVSownROf4XXYO";

    public static void main(String[] argv) {
        ConnectionFactory factory = new ConnectionFactory();
        //System.err.println(System.getenv("RABBIT_HOST"));
        //System.err.println(System.getenv("RABBIT_USER"));
        //System.err.println(System.getenv("RABBIT_PASSWORD"));
        factory.setHost(RABBIT_HOST);
        factory.setUsername(RABBIT_USER);
        factory.setPassword(RABBIT_PASSWORD);

        while(true) {
            final Connection connection;
            final Channel channel;
            try {
                connection = factory.newConnection();
                channel = connection.createChannel();

                Map<String, Object> arguments = new HashMap<>();
                arguments.put("x-queue-type", "quorum");
                channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, arguments);
                //channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, null);
                System.out.println(" [*] Waiting for messages. To exit press CTRL+C");

                channel.basicQos(1);

                DeliverCallback deliverCallback = (consumerTag, delivery) -> {
                    String message = new String(delivery.getBody(), "UTF-8");

                    System.out.println(" [x] Received '" + message + "'");
                    try {
                        doWork(message);
                    } finally {
                        System.out.println(" [x] Done");
                        channel.basicAck(delivery.getEnvelope().getDeliveryTag(), false);
                    }
                };


                channel.basicConsume(TASK_QUEUE_NAME, false, deliverCallback, consumerTag -> {});

                while(connection.isOpen()) {
                    Thread.sleep(1);
                }
            } catch (Exception ignored) {}
        }
    }

    private static void doWork(String task) {
        for (char ch : task.toCharArray()) {
            if (ch == '.') {
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException _ignored) {
                    Thread.currentThread().interrupt();
                }
            }
        }
    }

}