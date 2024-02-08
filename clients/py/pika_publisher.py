import time
import uuid
import pika
from pika.exchange_type import ExchangeType
import logging

class Publisher(object):
    """
    Publisher
    """
    def __init__(self, config, section='publisher'):
        """
        Initalize publisher

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

    def send(self, msg):
        """
        Send a message to RabbitMQ.

        :param str msg: message to send
        """
        properties = pika.BasicProperties(app_id=self._conf['app_id'],
                                          delivery_mode=self._conf['delivery_mode'],
                                          reply_to=self._conf['reply_to'],
                                          content_type='text/plain',
                                          timestamp=int(time.time()))
        res = self.channel.basic_publish(exchange=self._conf['exchange_name'],
                                         routing_key=self._conf['routing_keys'],
                                         body=msg,
                                         properties=properties,
                                         mandatory=False)

    def close(self):
        """
        Close the connection.
        """
        self.connection.close()
        if self._logger != None:
            self._logger.info('Close connection')

config = {
	"publisher1": {
		"app_id": "",
        "amqp_url": "amqp://publisher:publisher@127.0.0.1:5672/vhost",
		"exchange_name": "my.exchange",
	    "exchange_type": "topic",
		"routing_keys": "test-key1",
		"delivery_mode": 1,
		"reply_to": ""
	},
    "publisher2": {
		"app_id": "",
        "amqp_url": "amqp://publisher:publisher@127.0.0.1:5672/vhost",
		"exchange_name": "my.exchange",
	    "exchange_type": "topic",
		"routing_keys": "test-key2",
		"delivery_mode": 1,
		"reply_to": ""
	}
}

""" main function """
LOG_FORMAT = ('%(levelname) -5s %(asctime)s %(name) -10s %(funcName) '
                '-15s %(lineno) -5d: %(message)s')

logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)
logger = logging.getLogger()

try:
    config['logger'] = logger
    publisher1 = Publisher(config, 'publisher1')
    publisher2 = Publisher(config, 'publisher2')
    publisher1.connect()
    publisher2.connect()
    try:
        i = 1
        logger.info('Start sending messages...')
        while True:
            id = str(uuid.uuid4())
            message = '{"id":"' + id +'", "msg": "message ' + str(i) +'"}'
            publisher1.send(message)
            publisher2.send(message)
            i += 1
    except KeyboardInterrupt:
        publisher1.close()
        publisher2.close()
        logger.info('Stop')
except Exception as error:
    print("Error: %s" % (error, ))
