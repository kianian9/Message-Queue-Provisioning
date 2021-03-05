package consumer;

import io.nats.client.Connection;
import io.nats.client.Nats;
import io.nats.streaming.*;
import org.w3c.dom.ls.LSOutput;

import java.io.IOException;
import java.time.Duration;
import java.util.Random;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeoutException;

public class StanConsumer_Producer {


    // https://github.com/nats-io/stan.jav
    // https://docs.nats.io/nats-streaming-concepts/client-connections
    // https://docs.nats.io/developing-with-nats-streaming/connecting

    // THIS WORKS!
    public static void main(String[] args) throws IOException {
        Random random = new Random();
        // LB IP
        String lbIP = "35.228.243.110";

        // NATS Core Server URL For Connection To NATS Core
        String natsServerURL = "nats://" + lbIP +":4222";
        //Connection nc = Nats.connect("nats://myhost:4222");
        String clusterID = "stan";
        String clientID = "hejhej";

        String subject = "jadete";

        Connection nc = null;
        try {
            nc = Nats.connect(natsServerURL);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }

        // Alt 1 - This can fail due too slow responses==timeout
        /*
        //Options streamingOptions = new Options.Builder().natsConn(nc).build();
        Options streamingOptions = new Options.Builder().
                connectWait(Duration.ofSeconds(10)).natsConn(nc).build();

        StreamingConnection sc = null;

        try {
            sc = NatsStreaming.connect(clusterID, clientID, streamingOptions);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            System.exit(-1);
        }
        */



        // Alt 2 - This does not fail as often as Alt 1 (pga timeout)
        // Create a connection factory
        ///*
        StreamingConnectionFactory cf = new StreamingConnectionFactory(clusterID, clientID);
        cf.setNatsConnection(nc);


        // A StreamingConnection is a logical connection to the NATS streaming
        // server.  This API creates an underlying core NATS connection for
        // convenience and simplicity.  In most cases one would create a secure
        // core NATS connection and pass it in via
        // StreamingConnectionFactory.setNatsConnection(Connection nc)
        StreamingConnection sc = null;
        try {
            sc = cf.createConnection();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        //*/

        // This simple synchronous publish API blocks until an acknowledgement
        // is returned from the server.  If no exception is thrown, the message
        // has been stored in NATS streaming.

        try {
            String msg = "Hello World " + random.nextInt();
            sc.publish(subject, msg.getBytes());
        } catch (IOException | InterruptedException | TimeoutException e) {
            e.printStackTrace();
        }


        // Use a countdown latch to wait for our subscriber to receive the
        // message we published above.
        // Gets 50 first messages for subject
        final CountDownLatch doneSignal = new CountDownLatch(50);

        // Simple Async Subscriber that retrieves all available messages.
        Subscription sub = null;
        try {
            sub = sc.subscribe(subject, new MessageHandler() {
                public void onMessage(Message m) {
                    System.out.printf("Received a message: %s\n", new String(m.getData()));
                    doneSignal.countDown();
                }
            }, new SubscriptionOptions.Builder().deliverAllAvailable().build());
        } catch (IOException | InterruptedException | TimeoutException e) {
            e.printStackTrace();
            sub.unsubscribe();
            System.exit(1);
        }

        try {
            doneSignal.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        // Unsubscribe to clean up
        sub.unsubscribe();

        // Close the logical connection to NATS streaming
        try {
            sc.close();
        } catch (TimeoutException | InterruptedException e) {
            e.printStackTrace();
        }
        System.exit(1);
    }
}
