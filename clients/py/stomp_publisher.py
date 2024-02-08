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
for i in range(500000):
    conn.send(body='my message {}'.format(i), destination='stomp')
conn.disconnect()