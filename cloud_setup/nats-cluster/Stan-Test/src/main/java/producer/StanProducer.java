package producer;

import io.nats.client.Connection;
import io.nats.client.Nats;
import io.nats.streaming.NatsStreaming;
import io.nats.streaming.Options;
import io.nats.streaming.StreamingConnection;

import java.io.IOException;
import java.time.Duration;
import java.util.Random;
import java.util.concurrent.TimeoutException;

public class StanProducer {

    // MAY NOT WORK, CHECK StanConsumer_Producer
    public static void main(String[] args) {
        Random random = new Random();
        // LB IP
        String lbIP = "35.228.104.216";

        // NATS Core Server URL For Connection To NATS Core
        String natsServerURL = "nats://" + lbIP +":4222";
        //Connection nc = Nats.connect("nats://myhost:4222");
        String clusterID = "stan";
        String clientID = "producer";

        Connection nc = null;
        try {
            nc = Nats.connect(natsServerURL);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }

        // Alt 1 - This can fail due too slow responses==timeout
        ///*
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
        String msg = "Hello World " + random.nextInt();
        try {
            sc.publish("ny", msg.getBytes());
        } catch (IOException | InterruptedException | TimeoutException e) {
            e.printStackTrace();
        }
        System.out.println("Has published message: " + msg);
        try {
            sc.close();
            nc.close();
        } catch (IOException | TimeoutException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
