#!/bin/bash

set -e

# topology
docker-compose exec rabbitmq1 rabbitmqadmin -u rabbit -p rabbit -V vhost declare queue name=stream arguments='{"x-queue-type": "stream"}'