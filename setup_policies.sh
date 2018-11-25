#!/bin/bash

set -e

# dead letter exchange
config='{"ha-mode":"all", "ha-sync-mode":"automatic", "dead-letter-exchange":"dlx.events"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost ha-events ".\.events" "${config}" --priority 2 --apply-to queues

# lazy queues
# https://www.cloudamqp.com/blog/2017-07-05-solving-the-thundering-herd-problem-with-lazy-queues.html
lazyconfig='{"queue-mode":"lazy", "ha-mode":"all", "ha-sync-mode":"automatic"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost ha-lazy "^(?!amq\.).+" "${lazyconfig}" --priority 1 --apply-to queues
