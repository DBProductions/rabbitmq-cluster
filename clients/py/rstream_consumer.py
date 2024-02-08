import asyncio
import signal

from rstream import (
    AMQPMessage,
    Consumer,
    ConsumerOffsetSpecification,
    MessageContext,
    OffsetType,
    amqp_decoder,
)

STREAM = "my.stream"
OFFSET = 0

async def consume():
    consumer = Consumer(
        host="127.0.0.1",
        port=5552,
        vhost="vhost",
        username="consume_stream",
        password="stream",
        connection_name="rstream-consumer"
    )

    loop = asyncio.get_event_loop()
    loop.add_signal_handler(signal.SIGINT, lambda: asyncio.create_task(consumer.close()))

    async def on_message(msg: AMQPMessage, message_context: MessageContext):
        stream = message_context.consumer.get_stream(message_context.subscriber_name)
        offset = message_context.offset
        print("Got message: {} from stream {}, offset {}".format(msg, stream, offset))

    await consumer.start()
    await consumer.subscribe(
        stream=STREAM,
        callback=on_message,
        decoder=amqp_decoder,
        offset_specification=ConsumerOffsetSpecification(OffsetType.OFFSET, OFFSET)
    )
    await consumer.run()


asyncio.run(consume())