import time
import stomp

class MyListener(stomp.ConnectionListener):
    def on_error(self, frame):
        print('received an error "%s"' % frame.body)

    def on_message(self, frame):
        print('received a message "%s"' % frame.body)

conn = stomp.Connection()
conn.set_listener('', MyListener())
conn.transport.vhost = 'vhost'
conn.connect('rabbit', 'rabbit', wait=True)
conn.subscribe(destination='stomp', id=1, ack='auto')
time.sleep(5*60)
conn.disconnect()