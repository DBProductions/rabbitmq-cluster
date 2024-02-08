import uuid
import paho.mqtt.client as mqtt

# Define event callbacks
def on_connect(client, userdata, flags, rc):
    print("rc: " + str(rc))

def on_message(client, obj, msg):
    print(msg.topic + " " + str(msg.qos) + " " + str(msg.payload))

def on_publish(client, obj, mid):
    print("mid: " + str(mid))

def on_log(client, obj, level, string):
    print(string)

mqttc = mqtt.Client()
# Assign event callbacks
mqttc.on_message = on_message
mqttc.on_connect = on_connect
mqttc.on_publish = on_publish

# Uncomment to enable debug messages
#mqttc.on_log = on_log

topic = 'test/topic'
vhost = 'vhost'
username = 'rabbit'
password = 'rabbit'

# Connect
mqttc.username_pw_set('{}:{}'.format(vhost, username), password)
mqttc.connect('127.0.0.1', 1883)

# Publish a message
for i in range(500000):
    id = uuid.uuid4()
    mqttc.publish(topic, "data: {}".format(id))
