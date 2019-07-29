#!/bin/bash

# create admin user
docker-compose exec rabbitmq1 rabbitmqctl add_user teamA teamA
docker-compose exec rabbitmq1 rabbitmqctl set_user_tags teamA administrator

docker-compose exec rabbitmq2 rabbitmqctl add_user teamB teamB
docker-compose exec rabbitmq2 rabbitmqctl set_user_tags teamB administrator

# create monitoring user
docker-compose exec rabbitmq1 rabbitmqctl add_user monitor monitor
docker-compose exec rabbitmq1 rabbitmqctl set_user_tags monitor monitoring

docker-compose exec rabbitmq2 rabbitmqctl add_user monitor monitor
docker-compose exec rabbitmq2 rabbitmqctl set_user_tags monitor monitoring

# create user for each service
docker-compose exec rabbitmq1 rabbitmqctl add_user serviceA serviceA
docker-compose exec rabbitmq1 rabbitmqctl add_user serviceB serviceB

docker-compose exec rabbitmq2 rabbitmqctl add_user serviceA serviceA
docker-compose exec rabbitmq2 rabbitmqctl add_user serviceB serviceB

# set permissions
docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost teamA ".*" ".*" ".*"

docker-compose exec rabbitmq2 rabbitmqctl set_permissions -p vhost teamB ".*" ".*" ".*"

docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost serviceA "" "" ".*"
docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost serviceB "" ".*" ""
docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost monitor "" "" ""

docker-compose exec rabbitmq2 rabbitmqctl set_permissions -p vhost serviceA "" "" ".*"
docker-compose exec rabbitmq2 rabbitmqctl set_permissions -p vhost serviceB "" ".*" ""
docker-compose exec rabbitmq2 rabbitmqctl set_permissions -p vhost monitor "" "" ""

# federation
## topology
docker-compose exec rabbitmq1 rabbitmqadmin -u teamA -p teamA -V vhost declare exchange name=rabbitmq2.federated.events type=topic
docker-compose exec rabbitmq1 rabbitmqadmin -u teamA -p teamA -V vhost declare queue name=system.events durable=true
docker-compose exec rabbitmq1 rabbitmqadmin -u teamA -p teamA -V vhost declare binding source="rabbitmq2.federated.events" destination_type="queue" destination="system.events" routing_key="system.create.event"

## upstream
config='{"max-hops": 1, "uri": "amqp://teamB:teamB@rabbitmq2:5672/vhost", "ack-mode":"on-publish"}'
docker-compose exec rabbitmq1 rabbitmqctl set_parameter -p vhost federation-upstream rabbitmq2 "${config}"
config='[{"upstream": "rabbitmq2"}]'
docker-compose exec rabbitmq1 rabbitmqctl set_parameter -p vhost federation-upstream-set rabbitmq2 "${config}"

## set policy
config='{"federation-upstream-set": "rabbitmq2"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost --apply-to exchanges federation_rabbitmq2 "rabbitmq2.federated.*" "${config}"
config='{"ha-mode": "all"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost ha-federation "^federation:*" "${config}"

# shovel
## topology
docker-compose exec rabbitmq1 rabbitmqadmin -u teamA -p teamA -V vhost declare queue name=shovel durable=true
docker-compose exec rabbitmq2 rabbitmqadmin -u teamB -p teamB -V vhost declare exchange name=rabbitmq1.shovel type=direct
docker-compose exec rabbitmq2 rabbitmqadmin -u teamB -p teamB -V vhost declare queue name=shovel durable=true
docker-compose exec rabbitmq2 rabbitmqadmin -u teamB -p teamB -V vhost declare binding source="rabbitmq1.shovel" destination_type="queue" destination="shovel" routing_key="shovel"

## shovel 1 to 2
config='{"src-protocol": "amqp091", "src-uri": "amqp://teamA:teamA@rabbitmq1:5672/vhost", "src-queue": "shovel", "dest-protocol": "amqp091", "dest-uri": "amqp://teamB:teamB@rabbitmq2:5672/vhost", "dest-exchange": "rabbitmq1.shovel"}'
docker-compose exec rabbitmq1 rabbitmqctl set_parameter -p vhost shovel rabbitmq2 "${config}"