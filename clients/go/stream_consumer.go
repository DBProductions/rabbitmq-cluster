package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"sync/atomic"
	"time"

	"github.com/rabbitmq/rabbitmq-stream-go-client/pkg/amqp"
	"github.com/rabbitmq/rabbitmq-stream-go-client/pkg/stream"
)

var (
	host       = flag.String("host", "127.0.0.1", "Host")
	port       = flag.Int("port", 5552, "Port")
	vhost      = flag.String("vhost", "vhost", "VIRTUAL HOST")
	user       = flag.String("user", "consume_stream", "User")
	password   = flag.String("password", "stream", "Password")
	streamName = flag.String("stream", "my.stream", "Stream")
)

func CheckErr(err error) {
	if err != nil {
		fmt.Printf("%s ", err)
		os.Exit(1)
	}
}

func main() {
	reader := bufio.NewReader(os.Stdin)

	fmt.Println("Connecting to RabbitMQ streaming ...")

	env, err := stream.NewEnvironment(
		stream.NewEnvironmentOptions().
			SetHost(*host).
			SetPort(*port).
			SetUser(*user).
			SetPassword(*password).
			SetVHost(*vhost))
	CheckErr(err)

	CheckErr(err)

	var counter int32
	handleMessages := func(consumerContext stream.ConsumerContext, message *amqp.Message) {
		fmt.Printf("messages consumed: %d %s from stream %s \n", atomic.AddInt32(&counter, 1), string(message.GetData()), consumerContext.Consumer.GetStreamName())
	}

	consumerOffsetNumber, err := env.NewConsumer(*streamName,
		handleMessages,
		stream.NewConsumerOptions().
			SetConsumerName("my_consumer"). // set a consumerOffsetNumber name
			SetOffset(stream.OffsetSpecification{}.Offset(100)))
	// start specific offset, in this case we start from the 100 so it will consume 100 messages
	// see the others stream.OffsetSpecification{}.XXX
	CheckErr(err)

	/// wait a bit just for demo and reset the counters
	time.Sleep(2 * time.Second)
	atomic.StoreInt32(&counter, 0)

	consumerNext, err := env.NewConsumer(*streamName,
		handleMessages,
		stream.NewConsumerOptions().
			SetConsumerName("my_consumer_1").                // set a consumerOffsetNumber name
			SetOffset(stream.OffsetSpecification{}.First())) // with first() the the stream is loaded from the beginning
	CheckErr(err)

	fmt.Println("Press any key to stop ")
	_, _ = reader.ReadString('\n')
	//err = producer.Close()
	//CheckErr(err)
	err = consumerOffsetNumber.Close()
	CheckErr(err)
	err = consumerNext.Close()
	CheckErr(err)
	err = env.DeleteStream(*streamName)
	CheckErr(err)
}
