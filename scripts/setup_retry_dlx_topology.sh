#!/bin/bash

# exchanges
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare exchange name=events type=topic
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare exchange name=dlx.events type=topic
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare exchange name=dlx.retry type=topic

# queues
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=api.events durable=true
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=dead-events durable=true arguments='{"x-message-ttl":5000}'

# bindings
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="events" destination_type="queue" destination="api.events" routing_key="user.create.account"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="events" destination_type="queue" destination="api.events" routing_key="user.update.account"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="events" destination_type="queue" destination="api.events" routing_key="user.delete.account"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="dlx.events" destination_type="queue" destination="dead-events" routing_key="*.*.*"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="dlx.retry" destination_type="queue" destination="api.events" routing_key="user.create.account"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="dlx.retry" destination_type="queue" destination="api.events" routing_key="user.update.account"
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare binding source="dlx.retry" destination_type="queue" destination="api.events" routing_key="user.delete.account"

# policies
config='{"ha-mode":"all", "ha-sync-mode":"automatic", "dead-letter-exchange":"dlx.events"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost ha-events ".\.events" "${config}" --priority 2 --apply-to queues

config='{"ha-mode":"all", "ha-sync-mode":"automatic", "dead-letter-exchange":"dlx.retry"}'
docker-compose exec rabbitmq1 rabbitmqctl set_policy -p vhost ha-retry-events "dead-events" "${config}" --priority 2 --apply-to queues