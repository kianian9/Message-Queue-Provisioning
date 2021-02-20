package producer;
import com.rabbitmq.client.*;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;



public class RabbitProducer {
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

        //Attempts to reconnect on failure
        while (true) {
            final Connection connection;
            final Channel channel;
            try {
                connection = factory.newConnection();
                channel = connection.createChannel();
                Map<String, Object> arguments = new HashMap<>();
                arguments.put("x-queue-type", "quorum");
                channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, arguments);
                //channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, null);

                String message = "Test - " + new Random().nextInt(1000);


                while (true) {
                    channel.basicPublish("", TASK_QUEUE_NAME,
                            MessageProperties.PERSISTENT_TEXT_PLAIN,
                            message.getBytes(StandardCharsets.UTF_8));
                    System.out.println(" [x] Sent '" + message + "'");
                    Thread.sleep(5000);
                }
            } catch (Exception ignored) {}
        }
    }

}
