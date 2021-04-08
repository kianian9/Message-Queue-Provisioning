# Specifies a Java runtime as parent image for container
FROM adoptopenjdk/openjdk8:alpine-jre

# Sets the working directory to /app
WORKDIR /app


# Defining built-time variables(arguments)
ARG CLIENT_HANDLER_JAR_FILE=target/Kafka-Test-1.0-SNAPSHOT-jar-with-dependencies.jar


COPY ${CLIENT_HANDLER_JAR_FILE} app.jar


# Executes the application in the container
ENTRYPOINT ["java","-cp","app.jar", "producer.TestProducer"]
