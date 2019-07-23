#!/bin/bash

set -e

# topology
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=shovel durable=true
docker-compose exec rabbitmq2 rabbitmqadmin -u rabbit -p rabbit -V vhost declare exchange name=rabbitmq1.shovel type=direct
docker-compose exec rabbitmq2 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=shovel durable=true
docker-compose exec rabbitmq2 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="rabbitmq1.shovel" destination_type="queue" destination="shovel" routing_key="shovel"
docker-compose exec rabbitmq3 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=shovel durable=true

# shovel 1 to 2
config='{"src-protocol": "amqp091", "src-uri": "amqp://rabbit:rabbit@rabbitmq1:5672/vhost", "src-queue": "shovel", "dest-protocol": "amqp091", "dest-uri": "amqp://rabbit:rabbit@rabbitmq2:5672/vhost", "dest-exchange": "rabbitmq1.shovel"}'
docker-compose exec rabbitmq1 rabbitmqctl set_parameter -p vhost shovel rabbitmq2 "${config}"

# shovel 2 to 3
config='{"src-protocol": "amqp091", "src-uri": "amqp://rabbit:rabbit@rabbitmq2:5672/vhost", "src-queue": "shovel", "dest-protocol": "amqp091", "dest-uri": "amqp://rabbit:rabbit@rabbitmq3:5672/vhost", "dest-queue": "shovel"}'
docker-compose exec rabbitmq2 rabbitmqctl set_parameter -p vhost shovel rabbitmq3 "${config}"