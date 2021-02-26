package producer;
import com.rabbitmq.client.*;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;



public class RabbitProducer {
    private static final String TASK_QUEUE_NAME = "task_queue";
    private static String RABBIT_HOST = "35.228.188.246";
    private static String RABBIT_USER = "3KsEAdMVfCAqXB9QLsF-AtoxnC2Nz4GL";
    private static String RABBIT_PASSWORD = "7aYo7YHuutAne0P7ybKgGYlGpGpIphw6";


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
                //channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, arguments);
                channel.exchangeDeclare("logs", "fanout");
                //channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, null);

                String message = "Test - " + new Random().nextInt(1000);


                for (int i = 0; i < 1000000; i++) {
                    channel.basicPublish("logs", "",
                            null,
                            message.getBytes(StandardCharsets.UTF_8));
                    System.out.println(" [x] Sent '" + message + "'");
                    //Thread.sleep(100);
                }
                isDone = true;
            } catch (Exception ignored) {}
        }
    }

}
