# Clients

Some clients to play around with RabbitMQ they work with the `rabbitmq1` broker up and running.  
Use `setup.sh` to set up the user, permissions and topology and `cleanup.sh` to remove it.  

    ./setup.sh
    ./cleanup.sh

## Python
The Python clients are based on [pika](https://github.com/pika/pika), [paho-mqtt](https://github.com/eclipse/paho.mqtt.python), [rstream](https://github.com/qweeze/rstream/tree/master) and [stomp.py](https://github.com/jasonrbriggs/stomp.py).  
They use AMQP, MQTT, STOMP and the stream protocol supported from RabbitMQ.  
Dependency management is done with [poetry](https://python-poetry.org/).  

    cd /clients/py

    poetry run python pika_publisher.py
    poetry run python pika_consumer.py

    poetry run python mqtt_publisher.py
    poetry run python mqtt_consumer.py

    poetry run python rstream_publisher.py
    poetry run python rstream_consumer.py

    poetry run python stomp_publisher.py
    poetry run python stomp_consumer.py

## Go
The Go clients use [amqp091-go](https://github.com/rabbitmq/amqp091-go/) and [rabbitmq-stream-go-client](https://github.com/rabbitmq/rabbitmq-stream-go-client) to work with RabbitMQ.  

    cd /clients/go

    go run publisher.go
    go run consumer.go

    go run stream_publisher.go
    go run stream_consumer.go
