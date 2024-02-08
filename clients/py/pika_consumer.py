import pika
import logging

class Consumer(object):
    """
    Consumer
    """
    def __init__(self, config, section='consumer'):
        """
        Initalize consumer

        :param dict config: Configuration dict
        """
        self._logger = config['logger']
        self._conf = config[section]
        self.connection = None
        self.channel = None

    def connect(self):
        """
        Create connection and create channel.
        """
        if self._logger != None:
            self._logger.info('Connecting to {}'.format(self._conf['amqp_url']))
        self.connection = pika.BlockingConnection(pika.URLParameters(self._conf['amqp_url']))
        self.channel = self.connection.channel()
        self.channel.basic_consume(self._conf['queue_name'], self.consume)
        self.channel.start_consuming()

    def consume(self, chan, method_frame, header_frame, body, userdata=None):
        """
        Consume messages.
        """
        self._logger.info('consume {} {} {} {}'.format(chan, method_frame, header_frame, body))
        self.channel.basic_ack(delivery_tag=method_frame.delivery_tag)

config = {
	"consumer1": {
		"app_id": "",
        "amqp_url": "amqp://consumer:consumer@127.0.0.1:5672/vhost",
		"queue_name": "my.queue"
	}
}

""" main function """
LOG_FORMAT = ('%(levelname) -5s %(asctime)s %(name) -10s %(funcName) '
                '-15s %(lineno) -5d: %(message)s')

logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
logger = logging.getLogger()

try:
    config['logger'] = logger
    consumer = Consumer(config, 'consumer1')
    consumer.connect()
except Exception as error:
    print("Error: %s" % (error, ))
