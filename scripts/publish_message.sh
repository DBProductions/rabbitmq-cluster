#!/bin/bash

properties='"properties":{"content_type": "application/json", "expiration": "20000"}'
routing_key='"routing_key": "user.create.account"'
data='"{\"name\":\"RabbitMQ\"}"'
payload='{'"$properties"', '"$routing_key"', "payload":'"$data"', "payload_encoding":"string"}'

for i in {1..50}
do
  echo $(curl -s -H "content-type:application/json" -X POST -d "${payload}" http://rabbit:rabbit@localhost:15672/api/exchanges/vhost/events/publish)
done
