#!/bin/bash

set -e

# user
docker-compose exec rabbitmq2 rabbitmqctl add_user federal federal
docker-compose exec rabbitmq2 rabbitmqctl set_permissions -p vhost federal ".*" ".*" ".*"

docker-compose exec rabbitmq3 rabbitmqctl add_user federal federal
docker-compose exec rabbitmq3 rabbitmqctl set_permissions -p vhost federal ".*" ".*" ".*"

# topology
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare exchange name=rabbitmq2.federated.events type=topic
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=system.events durable=true
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=federated.events durable=true
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="rabbitmq2.federated.events" destination_type="queue" destination="system.events" routing_key="system.create.event"

# upstream for rabbitmq2
config='{"uri": "amqp://federal:federal@rabbitmq2:5672/vhost", "ack-mode":"on-confirm", "reconnect-delay": 1, "prefetch-count": 200, "max-hops": 1}'
docker-compose exec rabbitmq1 rabbitmqctl set_parameter -p vhost federation-upstream rabbitmq2 "${config}"
config='[{"upstream": "rabbitmq2"}]'
docker-compose exec rabbitmq1 rabbitmqctl set_parameter -p vhost federation-upstream-set rabbitmq2 "${config}"

# upstream for rabbitmq3
config='{"uri": "amqp://federal:federal@rabbitmq3:5672/vhost", "ack-mode":"on-confirm", "reconnect-delay": 1, "prefetch-count": 200}'
docker-compose exec rabbitmq1 rabbitmqctl set_parameter -p vhost federation-upstream rabbitmq3 "${config}"
config='[{"upstream": "rabbitmq3"}]'
docker-compose exec rabbitmq1 rabbitmqctl set_parameter -p vhost federation-upstream-set rabbitmq3 "${config}"

# set policy
config='{"federation-upstream-set": "rabbitmq2"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost --apply-to exchanges federation_rabbitmq2 "rabbitmq2.federated.*" "${config}"
config='{"ha-mode": "all"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost ha-federation "^federation:*" "${config}"

# set policy
config='{"federation-upstream-set": "rabbitmq3"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost --apply-to queues federation_rabbitmq3 "federated.*" "${config}"
config='{"ha-mode": "all"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost ha-federation "^federation:*" "${config}"
