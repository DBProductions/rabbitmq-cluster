package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

var (
	uri        = flag.String("uri", "amqp://publisher:publisher@127.0.0.1:5672/", "AMQP URI")
	vhost      = flag.String("vhost", "vhost", "VIRTUAL HOST")
	exchange   = flag.String("exchange", "my.exchange", "Durable AMQP exchange name")
	routingKey = flag.String("key", "my.key", "AMQP routing key")
	body       = flag.String("body", "message", "Body of message")
	continuous = flag.Bool("continuous", false, "Keep publishing messages at a 1msg/sec rate")
	WarnLog    = log.New(os.Stderr, "[WARNING] ", log.LstdFlags|log.Lmsgprefix)
	ErrLog     = log.New(os.Stderr, "[ERROR] ", log.LstdFlags|log.Lmsgprefix)
	Log        = log.New(os.Stdout, "[INFO] ", log.LstdFlags|log.Lmsgprefix)
)

func init() {
	flag.Parse()
}

func main() {
	exitCh := make(chan struct{})
	confirmsCh := make(chan *amqp.DeferredConfirmation)
	confirmsDoneCh := make(chan struct{})
	// Note: this is a buffered channel so that indicating OK to
	// publish does not block the confirm handler
	publishOkCh := make(chan struct{}, 1)

	setupCloseHandler(exitCh)

	startConfirmHandler(publishOkCh, confirmsCh, confirmsDoneCh, exitCh)

	publish(context.Background(), publishOkCh, confirmsCh, confirmsDoneCh, exitCh)
}

func setupCloseHandler(exitCh chan struct{}) {
	c := make(chan os.Signal, 2)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		Log.Printf("close handler: Ctrl+C pressed in Terminal")
		close(exitCh)
	}()
}

func publish(ctx context.Context, publishOkCh <-chan struct{}, confirmsCh chan<- *amqp.DeferredConfirmation, confirmsDoneCh <-chan struct{}, exitCh chan struct{}) {
	config := amqp.Config{
		Vhost:      *vhost,
		Properties: amqp.NewConnectionProperties(),
	}
	config.Properties.SetClientConnectionName("producer-with-confirms")

	Log.Printf("producer - connecting to: %s", *uri)
	conn, err := amqp.DialConfig(*uri, config)
	if err != nil {
		ErrLog.Fatalf("producer - error to connect: %s", err)
	}
	defer conn.Close()

	Log.Println("producer - got Connection, getting Channel")
	channel, err := conn.Channel()
	if err != nil {
		ErrLog.Fatalf("error getting a channel: %s", err)
	}
	defer channel.Close()

	// Reliable publisher confirms require confirm.select support from the connection.
	Log.Printf("producer: enabling publisher confirms.")
	if err := channel.Confirm(false); err != nil {
		ErrLog.Fatalf("producer: channel could not be put into confirm mode: %s", err)
	}

	for {
		canPublish := false
		Log.Println("producer: waiting on the OK to publish...")
		for {
			select {
			case <-confirmsDoneCh:
				Log.Println("producer: stopping, all confirms seen")
				return
			case <-publishOkCh:
				Log.Println("producer: got the OK to publish")
				canPublish = true
				break
			case <-time.After(time.Second):
				WarnLog.Println("producer: still waiting on the OK to publish...")
				continue
			}
			if canPublish {
				break
			}
		}

		Log.Printf("producer: publishing %dB body (%q)", len(*body), *body)
		dConfirmation, err := channel.PublishWithDeferredConfirmWithContext(
			ctx,
			*exchange,
			*routingKey,
			true,
			false,
			amqp.Publishing{
				Headers:         amqp.Table{},
				ContentType:     "text/plain",
				ContentEncoding: "",
				DeliveryMode:    amqp.Persistent,
				Priority:        0,
				AppId:           "sequential-producer",
				Body:            []byte(*body),
			},
		)
		if err != nil {
			ErrLog.Fatalf("producer: error in publish: %s", err)
		}

		select {
		case <-confirmsDoneCh:
			Log.Println("producer: stopping, all confirms seen")
			return
		case confirmsCh <- dConfirmation:
			Log.Println("producer: delivered deferred confirm to handler")
			break
		}

		select {
		case <-confirmsDoneCh:
			Log.Println("producer: stopping, all confirms seen")
			return
		case <-time.After(time.Millisecond * 250):
			if *continuous {
				continue
			} else {
				Log.Println("producer: initiating stop")
				close(exitCh)
				select {
				case <-confirmsDoneCh:
					Log.Println("producer: stopping, all confirms seen")
					return
				case <-time.After(time.Second * 10):
					WarnLog.Println("producer: may be stopping with outstanding confirmations")
					return
				}
			}
		}
	}
}

func startConfirmHandler(publishOkCh chan<- struct{}, confirmsCh <-chan *amqp.DeferredConfirmation, confirmsDoneCh chan struct{}, exitCh <-chan struct{}) {
	go func() {
		confirms := make(map[uint64]*amqp.DeferredConfirmation)

		for {
			select {
			case <-exitCh:
				exitConfirmHandler(confirms, confirmsDoneCh)
				return
			default:
				break
			}

			outstandingConfirmationCount := len(confirms)

			// Note: 8 is arbitrary, you may wish to allow more outstanding confirms before blocking publish
			if outstandingConfirmationCount <= 8 {
				select {
				case publishOkCh <- struct{}{}:
					Log.Println("confirm handler: sent OK to publish")
				case <-time.After(time.Second * 5):
					WarnLog.Println("confirm handler: timeout indicating OK to publish (this should never happen!)")
				}
			} else {
				WarnLog.Printf("confirm handler: waiting on %d outstanding confirmations, blocking publish", outstandingConfirmationCount)
			}

			select {
			case confirmation := <-confirmsCh:
				dtag := confirmation.DeliveryTag
				confirms[dtag] = confirmation
			case <-exitCh:
				exitConfirmHandler(confirms, confirmsDoneCh)
				return
			}

			checkConfirmations(confirms)
		}
	}()
}

func exitConfirmHandler(confirms map[uint64]*amqp.DeferredConfirmation, confirmsDoneCh chan struct{}) {
	Log.Println("confirm handler: exit requested")
	waitConfirmations(confirms)
	close(confirmsDoneCh)
	Log.Println("confirm handler: exiting")
}

func checkConfirmations(confirms map[uint64]*amqp.DeferredConfirmation) {
	Log.Printf("confirm handler: checking %d outstanding confirmations", len(confirms))
	for k, v := range confirms {
		if v.Acked() {
			Log.Printf("confirm handler: confirmed delivery with tag: %d", k)
			delete(confirms, k)
		}
	}
}

func waitConfirmations(confirms map[uint64]*amqp.DeferredConfirmation) {
	Log.Printf("confirm handler: waiting on %d outstanding confirmations", len(confirms))

	checkConfirmations(confirms)

	for k, v := range confirms {
		select {
		case <-v.Done():
			Log.Printf("confirm handler: confirmed delivery with tag: %d", k)
			delete(confirms, k)
		case <-time.After(time.Second):
			WarnLog.Printf("confirm handler: did not receive confirmation for tag %d", k)
		}
	}

	outstandingConfirmationCount := len(confirms)
	if outstandingConfirmationCount > 0 {
		ErrLog.Printf("confirm handler: exiting with %d outstanding confirmations", outstandingConfirmationCount)
	} else {
		Log.Println("confirm handler: done waiting on outstanding confirmations")
	}
}