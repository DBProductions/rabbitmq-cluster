#!/bin/bash

set -e

# user
docker-compose exec rabbitmq1 rabbitmqctl delete_user publisher
docker-compose exec rabbitmq1 rabbitmqctl delete_user consumer
docker-compose exec rabbitmq1 rabbitmqctl delete_user publish_stream
docker-compose exec rabbitmq1 rabbitmqctl delete_user consume_stream

# topology
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost delete exchange name=my.exchange
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost delete queue name=my.queue
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost delete queue name=my.stream
