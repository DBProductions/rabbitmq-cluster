import paho.mqtt.client as mqtt

# Define event callbacks
def on_connect(client, userdata, flags, rc):
    print("rc: " + str(rc))

def on_message(client, obj, msg):
    print(msg.topic + " " + str(msg.qos) + " " + str(msg.payload))

def on_subscribe(client, obj, mid, granted_qos):
    print("Subscribed: " + str(mid) + " " + str(granted_qos))

def on_log(client, obj, level, string):
    print(string)

mqttc = mqtt.Client()
# Assign event callbacks
mqttc.on_message = on_message
mqttc.on_connect = on_connect
mqttc.on_subscribe = on_subscribe

# Uncomment to enable debug messages
#mqttc.on_log = on_log

topic = 'test/topic'
vhost = 'vhost'
username = 'rabbit'
password = 'rabbit'

# Connect
mqttc.username_pw_set('{}:{}'.format(vhost, username), password)
mqttc.connect('127.0.0.1', 1883)

# Start subscribe, with QoS level 0
mqttc.subscribe(topic, 0)

# Continue the network loop, exit when an error occurs
rc = 0
while rc == 0:
    rc = mqttc.loop()
print("rc:- " + str(rc))