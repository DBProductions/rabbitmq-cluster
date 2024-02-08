#!/bin/bash

set -e

# user
docker-compose exec rabbitmq1 rabbitmqctl add_user publisher publisher
docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost publisher "" "my\.exchange" ""

docker-compose exec rabbitmq1 rabbitmqctl add_user consumer consumer
docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost consumer "" "" "my\.queue"

docker-compose exec rabbitmq1 rabbitmqctl add_user publish_stream stream
docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost publish_stream "" "my\.stream" ""

docker-compose exec rabbitmq1 rabbitmqctl add_user consume_stream stream
docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost consume_stream "" "" "my\.stream"

# topology
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare exchange name=my.exchange type=topic
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=my.queue durable=true
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="my.exchange" destination_type="queue" destination="my.queue" routing_key="#"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=my.stream durable=true arguments='{"x-queue-type": "stream", "x-max-age": "10m"}'
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="my.exchange" destination_type="queue" destination="my.stream" routing_key="#"