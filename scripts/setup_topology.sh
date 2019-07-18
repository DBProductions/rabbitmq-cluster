#!/bin/bash

# exchanges
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare exchange name=events type=topic
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare exchange name=dlx.events type=topic

# queues
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=api.events durable=true
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=dead-events durable=true

# bindings
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="events" destination_type="queue" destination="api.events" routing_key="user.create.account"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="events" destination_type="queue" destination="api.events" routing_key="user.update.account"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="events" destination_type="queue" destination="api.events" routing_key="user.delete.account"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="dlx.events" destination_type="queue" destination="dead-events" routing_key="*.*.*"
