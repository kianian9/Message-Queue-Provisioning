package producer;
import com.rabbitmq.client.*;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.UUID;


public class RabbitProducer {
    private static final String TASK_QUEUE_NAME = "task_queue";
    private static String RABBIT_HOST = "35.228.157.201";
    private static String RABBIT_USER = "MOXF3ljBPn3JWvt_4L_DZwmFKgt6JSyM";
    private static String RABBIT_PASSWORD = "ySA4T7oGGdc81J0vbMrxczYLqoSpCJOF";
    private static String exchange = "fanout";

    private static String queueName;
    public static void main(String[] argv) {
        ConnectionFactory factory = new ConnectionFactory();
        //System.err.println(System.getenv("RABBIT_HOST"));
        //System.err.println(System.getenv("RABBIT_USER"));
        //System.err.println(System.getenv("RABBIT_PASSWORD"));
        factory.setHost(RABBIT_HOST);
        factory.setUsername(RABBIT_USER);
        factory.setPassword(RABBIT_PASSWORD);

        //Attempts to reconnect on failure
        boolean isDone = false;
        while (!isDone) {
            final Connection connection;
            final Channel channel;
            try {
                connection = factory.newConnection();
                channel = connection.createChannel();
                //Map<String, Object> arguments = new HashMap<>();
                //arguments.put("x-queue-type", "quorum");
                //queueName = UUID.randomUUID().toString().replace("-", "");
                //channel.queueDeclare(queueName, true, false, false, arguments);
                //System.out.println(1);
                //channel.queueDeclare(queueName, true, false, false, arguments);
                //System.out.println(2);
                channel.exchangeDeclare(exchange, "fanout");
                //channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, null);



                long timestamp1 = System.currentTimeMillis();
                int nrMessages = 0;
                byte[] c = new byte[1000];
                for (int i = 0; i < 500000; i++) {
                    long timestamp2 = System.currentTimeMillis();
                    //String message = "Test - " + i;
                    String s = new String(c, StandardCharsets.UTF_8);
                    channel.basicPublish(exchange, "",
                            null,
                            s.getBytes(StandardCharsets.UTF_8));
                    //System.out.println(" [x] Sent '" + message + "'");
                    long time = (timestamp2 - timestamp1) / 1000;
                    if (time >= 1) {
                        System.out.println("Pub msgs per sec (approx): " + (i - nrMessages));
                        nrMessages = i;
                        timestamp1 = timestamp2;
                    }
                    //Thread.sleep(100);
                }
                isDone = true;
            } catch (Exception ignored) {}
        }
        System.out.println("Is done!");
    }

}
