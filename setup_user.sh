#!/bin/bash

set -e

docker-compose exec rabbitmq1 rabbitmqctl add_user consumer consumer
docker-compose exec rabbitmq1 rabbitmqctl add_user publisher publisher

docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost consumer "" "" ".*"
docker-compose exec rabbitmq1 rabbitmqctl set_permissions -p vhost publisher "" ".*" ""