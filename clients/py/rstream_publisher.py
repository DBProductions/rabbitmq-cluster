import time
import uuid
import asyncio
from rstream import (
    AMQPMessage,
    ConfirmationStatus,
    Producer,
)

HOST = '127.0.0.1'
VHOST = 'vhost'
USERNAME = 'publish_stream'
PASSWORD = 'stream'
STREAM = 'my.stream'
MESSAGES = 2_000_000

async def _on_publish_confirm_client(confirmation: ConfirmationStatus) -> None:
    if confirmation.is_confirmed:
        if (confirmation.message_id % 5000) == 0:
            print("message id: {} is confirmed".format(confirmation.message_id))
    else:
        print(
            "message id: {} not confirmed. Response code {}".format(
                confirmation.message_id, confirmation.response_code
            )
        )

async def publish() -> None:
    async with Producer(HOST, username=USERNAME, password=PASSWORD, vhost=VHOST) as producer:
        producer_id = str(uuid.uuid4())
        # sending a million of messages in AMQP format
        start_time = time.perf_counter()

        for i in range(MESSAGES):
            id = uuid.uuid4()
            amqp_message = AMQPMessage(
                body="data: {}".format(id)
            )
            # send is asynchronous
            await producer.send(stream=STREAM, message=amqp_message, publisher_name=producer_id, on_publish_confirm=_on_publish_confirm_client)

        end_time = time.perf_counter()
        print(f"Sent {MESSAGES} messages in {end_time - start_time:0.4f} seconds")

asyncio.run(publish())