package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/google/uuid"
	"github.com/rabbitmq/rabbitmq-stream-go-client/pkg/amqp"
	"github.com/rabbitmq/rabbitmq-stream-go-client/pkg/stream"
)

var (
	host       = flag.String("host", "127.0.0.1", "Host")
	port       = flag.Int("port", 5552, "Port")
	vhost      = flag.String("vhost", "vhost", "VIRTUAL HOST")
	user       = flag.String("user", "publish_stream", "User")
	password   = flag.String("password", "stream", "Password")
	streamName = flag.String("stream", "my.stream", "Stream")
	messages   = flag.Int("messages", 2000000, "Messages")
)

func CheckErr(err error) {
	if err != nil {
		fmt.Printf("%s ", err)
		os.Exit(1)
	}
}

func handlePublishConfirm(confirms stream.ChannelPublishConfirm) {
	go func() {
		for confirmed := range confirms {
			for _, msg := range confirmed {
				if msg.IsConfirmed() {
					fmt.Printf("message %s stored \n  ", msg.GetMessage().GetData())
				} else {
					fmt.Printf("message %s failed \n  ", msg.GetMessage().GetData())
				}

			}
		}
	}()
}

func main() {
	fmt.Println("Connecting to RabbitMQ streaming ...")

	env, err := stream.NewEnvironment(
		stream.NewEnvironmentOptions().
			SetHost(*host).
			SetPort(*port).
			SetUser(*user).
			SetPassword(*password).
			SetVHost(*vhost))
	CheckErr(err)

	producerId := uuid.New()
	producer, err := env.NewProducer(*streamName,
		stream.NewProducerOptions().SetProducerName(producerId.String()))
	CheckErr(err)

	//optional publish confirmation channel
	chPublishConfirm := producer.NotifyPublishConfirmation()
	handlePublishConfirm(chPublishConfirm)

	// the send method automatically aggregates the messages
	// based on batch size
	for i := 0; i < *messages; i++ {
		id := uuid.New()
		err := producer.Send(amqp.NewMessage([]byte("data: " + id.String())))
		CheckErr(err)
	}

	// this sleep is not mandatory, just to show the confirmed messages
	time.Sleep(1 * time.Second)
	err = producer.Close()
	CheckErr(err)
}
