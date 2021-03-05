package consumer;

import io.nats.client.Connection;
import io.nats.client.Nats;
import io.nats.client.Options;
import io.nats.streaming.*;
//import io.nats.streaming.*;

import java.io.IOException;
import java.time.Duration;
import java.util.Random;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeoutException;

public class StanConsumer {

    // MAY NOT WORK, CHECK StanConsumer_Producer
    public static void main(String[] args) {
        // LB IP
        String lbIP = "35.228.243.110";

        // NATS Core Server URL For Connection To NATS Core
        String natsServerURL = "nats://" + lbIP +":4222";
        //Connection nc = Nats.connect("nats://myhost:4222");
        String clusterID = "stan";
        String clientID = "consumer";

        Connection nc = null;
        try {
            Options options = new Options.Builder().server(natsServerURL).connectionTimeout(Duration.ofSeconds(10)).reconnectWait(Duration.ofSeconds(1)).build();
            nc = Nats.connect(options);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }

        // Alt 1 - This can fail due too slow responses==timeout
        /*
        io.nats.streaming.Options streamingOptions = new io.nats.streaming.Options.Builder().natsConn(nc)..build();
        //io.nats.streaming.Options streamingOptions = new io.nats.streaming.Options.Builder().
        //        connectWait(Duration.ofSeconds(10)).natsConn(nc).build();


        StreamingConnection sc = null;
        int retries = 5;
        int tries = 0;
        while (tries != retries) {
            try {
                sc = NatsStreaming.connect(clusterID, clientID, streamingOptions);
                System.out.println("Connected!");
                break;
            } catch (IOException | InterruptedException e) {
                System.out.println("Retrying...");
                tries++;
            }
        }
        */



        // Alt 2 - This does not fail as often as Alt 1 (pga timeout)
        // Create a connection factory
        ///*
        //io.nats.streaming.Options streamingOptions = new io.nats.streaming.Options.Builder().
        //        connectWait(Duration.ofSeconds(10)).natsConn(nc).clusterId(clusterID).clientId(clientID).build();
        //StreamingConnectionFactory cf = new StreamingConnectionFactory(streamingOptions);

        StreamingConnectionFactory cf = new StreamingConnectionFactory(clusterID, clientID);



        // A StreamingConnection is a logical connection to the NATS streaming
        // server.  This API creates an underlying core NATS connection for
        // convenience and simplicity.  In most cases one would create a secure
        // core NATS connection and pass it in via
        cf.setNatsConnection(nc);
        StreamingConnection sc = null;
        try {
            sc = cf.createConnection();
            //sc = NatsStreaming.connect(clusterID, clientID, streamingOptions);
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
            System.exit(-1);
        }
        //*/

        // Use a countdown latch to wait for our subscriber to receive the
        // message we published above.
        final CountDownLatch doneSignal = new CountDownLatch(100000);

        // Simple Async Subscriber that retrieves all available messages.
        Subscription sub = null;
        try {
            sub = sc.subscribe("kian-subject", new MessageHandler() {
                public void onMessage(Message m) {
                    System.out.printf("Received a message: %s\n", new String(m.getData()));
                    doneSignal.countDown();
                }
            }, new SubscriptionOptions.Builder().deliverAllAvailable().build());
        } catch (IOException | InterruptedException | TimeoutException e) {
            e.printStackTrace();
            try {
                sub.unsubscribe();
            } catch (IOException ioException) {
                ioException.printStackTrace();
            }
            System.exit(1);
        }

        try {
            doneSignal.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        // Unsubscribe to clean up
        try {
            sub.unsubscribe();
        } catch (IOException e) {
            e.printStackTrace();
        }

        // Close the logical connection to NATS streaming
        try {
            sc.close();
        } catch (TimeoutException | InterruptedException | IOException e) {
            e.printStackTrace();
        }
        System.exit(1);
    }
}
