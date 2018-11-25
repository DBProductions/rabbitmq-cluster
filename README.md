# RabbitMQ

This repository gives the possibility to play around with RabbitMQ.  
Should helps to understand how clustering and mirroring works.  

# Docker

The `docker-compose` file contains three RabbitMQ services rabbitmq1, rabbitmq2 and rabbitmq3.  
The admin user (rabbit) and password (rabbit) are on all nodes the same.  

    $ docker-compose up

# Scripts

A collection of scripts use rabbitmqadmin, rabbitmqctl and curl to create Cluster, Exchanges, Queues, Bindings, Policies, User and publish a message.

`setup_cluster.sh` let rabbitmq2 and rabbitmq3 join rabbitmq1 as cluster.  

    $ ./setup_cluster.sh
    Stopping rabbit application on node rabbit@rabbitmq2 ...
    Clustering node rabbit@rabbitmq2 with rabbit@rabbitmq1
    Starting node rabbit@rabbitmq2 ...
    completed with 9 plugins.
    Stopping rabbit application on node rabbit@rabbitmq3 ...
    Clustering node rabbit@rabbitmq3 with rabbit@rabbitmq1
    Starting node rabbit@rabbitmq3 ...
    completed with 9 plugins.

`setup_user.sh` add user and set permissions.  

    $ ./setup_user.sh
    Adding user "consumer" ...
    Adding user "publisher" ...
    Setting permissions for user "consumer" in vhost "vhost" ...
    Setting permissions for user "publisher" in vhost "vhost" ...

The user and password are the same!  

`setup_topology.sh` add exchanges, queues and bindings.  

    $ ./setup_topology.sh
    exchange declared
    exchange declared
    queue declared
    queue declared
    binding declared
    binding declared
    binding declared
    binding declared

The topology is a simple event system with a 'dead-letter' configuration.  

![Topology](./topology.png?raw=true "Topology")

`setup_policies.sh` set policies for exchanges and queues.  

    $ ./setup_policies.sh
    Setting policy "ha-events" for pattern ".\.events" to "{"ha-mode":"all", "ha-sync-mode":"automatic", "dead-letter-exchange":"dlx.events"}" with priority "2" for vhost "vhost" ...
    Setting policy "ha-lazy" for pattern "^(?!amq\.).+" to "{"queue-mode":"lazy", "ha-mode":"all", "ha-sync-mode":"automatic"}" with priority "1" for vhost "vhost" ...

`publish_message.sh` publish a message

    $ ./publish_message.sh
    {"routed":true}