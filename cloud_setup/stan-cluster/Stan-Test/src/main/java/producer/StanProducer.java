package producer;

import io.nats.client.Connection;
import io.nats.client.Nats;
import io.nats.streaming.AckHandler;
import io.nats.streaming.NatsStreaming;
import io.nats.streaming.Options;
import io.nats.streaming.StreamingConnection;

import java.io.IOException;
import java.time.Duration;
import java.util.Random;
import java.util.concurrent.TimeoutException;

// Remember to now congest the servers (maxPubAcksInFlight)
public class StanProducer {

    public static void main(String[] args) {
        // LB IP
        String lbIP = "35.228.243.110";

        // NATS Core Server URL For Connection To NATS Core
        String natsServerURL = "nats://" + lbIP +":4222";
        //Connection nc = Nats.connect("nats://myhost:4222");
        String clusterID = "stan";
        String clientID = "producer";
        String subject = "kian-subject1";

        Connection nc = null;
        try {
            nc = Nats.connect(natsServerURL);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }

        // Alt 1 - This can fail due too slow responses==timeout
        ///*
        //Options streamingOptions = new Options.Builder().
        //        connectWait(Duration.ofSeconds(10)).natsConn(nc).maxPubAcksInFlight(100000).build();
        Options streamingOptions = new Options.Builder().
                connectWait(Duration.ofSeconds(10)).natsConn(nc).build();

        StreamingConnection sc = null;

        try {
            sc = NatsStreaming.connect(clusterID, clientID, streamingOptions);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            System.exit(-1);
        }
        //*/



        // Alt 2 - This does not fail as often as Alt 1 (pga timeout)
        // Create a connection factory
        /*
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
        */

        // This simple synchronous publish API blocks until an acknowledgement
        // is returned from the server.  If no exception is thrown, the message
        // has been stored in NATS streaming.
        long timestamp1 = System.currentTimeMillis();
        int nrMessages = 0;
        for (int i = 0; i < 100000000; i++) {
            long timestamp2 = System.currentTimeMillis();


            String msg = "Test - " + i;

            // Synchronous publishing
            /*
            try {
                sc.publish("kian-subject", msg.getBytes());
            } catch (IOException | InterruptedException | TimeoutException e) {
                e.printStackTrace();
            }
            */

            // Asynchronous publishing
            ///*
            // The ack handler will be invoked when a publish acknowledgement is received
            AckHandler ackHandler = new AckHandler() {
                public void onAck(String guid, Exception err) {
                    if (err != null) {
                        System.err.printf("Error publishing msg id %s: %s\n", guid, err.getMessage());
                    }
                    /*
                    if (err != null) {
                        System.err.printf("Error publishing msg id %s: %s\n", guid, err.getMessage());
                    } else {
                        System.out.printf("Received ack for msg id %s\n", guid);
                    }
                    */
                }
            };
            // This returns immediately.  The result of the publish can be handled in the ack handler.
            try {
                String guid = sc.publish(subject, msg.getBytes(), ackHandler);
            } catch (IOException | InterruptedException | TimeoutException e) {
                e.printStackTrace();
            }

            //*/
            //System.out.println("Has published message: " + msg);
            long time = (timestamp2 - timestamp1) / 1000;
            if (time >= 1) {
                System.out.println("Pub msgs per sec: " + (i - nrMessages));
                nrMessages = i;
                timestamp1 = timestamp2;
                System.out.println("Msg Not Received: " + (i - nc.getStatistics().getInMsgs()));
            }
        }

        try {
            sc.close();
        } catch (IOException | TimeoutException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
