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

