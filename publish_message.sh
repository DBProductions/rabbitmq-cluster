#!/bin/bash


payload='{"properties":{"content_type": "application/json", "expiration": "20000"}, "routing_key": "user.create.account","payload":"{\"name\":\"RabbitMQ\"}","payload_encoding":"string"}'
curl -H "content-type:application/json" -X POST -d "${payload}" http://rabbit:rabbit@localhost:15672/api/exchanges/vhost/events/publish
