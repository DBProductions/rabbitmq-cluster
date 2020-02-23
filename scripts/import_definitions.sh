#!/bin/bash

docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit import ./export/rabbitmq1.json
docker-compose exec rabbitmq2 rabbitmqadmin -u rabbit -p rabbit import ./export/rabbitmq2.json
docker-compose exec rabbitmq3 rabbitmqadmin -u rabbit -p rabbit import ./export/rabbitmq3.json