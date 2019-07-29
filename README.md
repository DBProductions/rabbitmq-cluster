# RabbitMQ

This repository gives the possibility to play around with RabbitMQ.  
Should help to understand how Clustering, Federation- and Shovel-Plugin are working.  

# Docker

The `docker-compose` file contains three RabbitMQ services `rabbitmq1`, `rabbitmq2` and `rabbitmq3`.  
The admin user (`rabbit`) and password (`rabbit`) are on all nodes the same.  

    $ docker-compose up --build

The management UIs can be found under `http://localhost:15672`, `http://localhost:15673` and `http://localhost:15674`.

Enabled plugins:
 - rabbitmq_mqtt 
 - rabbitmq_federation
 - rabbitmq_federation_management
 - rabbitmq_stomp 
 - rabbitmq_shovel 
 - rabbitmq_shovel_management

# Scripts

A collection of scripts using `rabbitmqadmin`, `rabbitmqctl` and `curl` to create Cluster, Upstreams, Exchanges, Queues, Bindings, Policies, User and publish messages.

### setup_federation.sh
Instead of joining a cluster, here we have three broker which are connected.  
On `rabbitmq1` we create two exchanges, a queue and two bindings then add two upstreams.  
This upstreams are connecting to `rabbitmq2` and `rabbitmq3` after the policies are applied.  
`rabbitmq2` and `rabbitmq3` gets exchanges created and messages are additional send to the exchanges on `rabbitmq1`.  
We have so called federated exchanges defined where `rabbitmq1` is the receiver from the two other broker.

    $ ./scripts/setup_federation.sh
    exchange declared
    exchange declared
    queue declared
    binding declared
    binding declared
    Setting runtime parameter "federation-upstream" for component "rabbitmq2" to "{"max-hops": 1, "uri": "amqp://rabbit:rabbit@rabbitmq2:5672/vhost", "ack-mode":"on-publish"}" in vhost "vhost" ...
    Setting runtime parameter "federation-upstream-set" for component "rabbitmq2" to "[{"upstream": "rabbitmq2"}]" in vhost "vhost" ...
    Setting runtime parameter "federation-upstream" for component "rabbitmq3" to "{"max-hops": 1, "uri": "amqp://rabbit:rabbit@rabbitmq3:5672/vhost", "ack-mode":"on-publish"}" in vhost "vhost" ...
    Setting runtime parameter "federation-upstream-set" for component "rabbitmq3" to "[{"upstream": "rabbitmq3"}]" in vhost "vhost" ...
    Setting policy "federation_rabbitmq2" for pattern "rabbitmq2.federated.*" to "{"federation-upstream-set": "rabbitmq2"}" with priority "0" for vhost "vhost" ...
    Setting policy "ha-federation" for pattern "^federation:*" to "{"ha-mode": "all"}" with priority "0" for vhost "vhost" ...
    Setting policy "federation_rabbitmq3" for pattern "rabbitmq3.federated.*" to "{"federation-upstream-set": "rabbitmq3"}" with priority "0" for vhost "vhost" ...
    Setting policy "ha-federation" for pattern "^federation:*" to "{"ha-mode": "all"}" with priority "0" for vhost "vhost" ...

### setup_shovel.sh
Instead of joining a cluster, here we have three broker which are connected.  
On all three broker we create a queue named `shovel`, on `rabbitmq1` and `rabbitmq2` we create a dynamic shovel.  
`rabbitmq2` have a additional exchange named `rabbitmq1.shovel` bind to the `shovel` queue on `rabbitmq2`.  
The queue on `rabbitmq1` is the source for the exchange on `rabbitmq2` and the queue on `rabbitmq2` is then the source for the queue on `rabbitmq3`.  
Every message published to `shovel` on `rabbitmq1` is shovelled to the exchange `rabbitmq1.shovel` on `rabbitmq2` then finally shovelled from the `shovel` queue on `rabbitmq2` to the `shovel` queue on `rabbitmq3`.

    $ ./scripts/setup_shovel.sh
    queue declared
    exchange declared
    queue declared
    binding declared
    queue declared
    Setting runtime parameter "shovel" for component "rabbitmq2" to "{"src-protocol": "amqp091", "src-uri": "amqp://rabbit:rabbit@rabbitmq1:5672/vhost", "src-queue": "shovel", "dest-protocol": "amqp091", "dest-uri": "amqp://rabbit:rabbit@rabbitmq2:5672/vhost", "dest-exchange": "rabbitmq1.shovel"}" in vhost "vhost" ...
    Setting runtime parameter "shovel" for component "rabbitmq3" to "{"src-protocol": "amqp091", "src-uri": "amqp://rabbit:rabbit@rabbitmq2:5672/vhost", "src-queue": "shovel", "dest-protocol": "amqp091", "dest-uri": "amqp://rabbit:rabbit@rabbitmq3:5672/vhost", "dest-queue": "shovel"}" in vhost "vhost" ...

### setup_cluster.sh 
Let `rabbitmq2` and `rabbitmq3` join `rabbitmq1` as cluster.  
When Shovel or Federation is used before the cluster will not work like expected!  

    $ ./scripts/setup_cluster.sh
    Stopping rabbit application on node rabbit@rabbitmq2 ...
    Clustering node rabbit@rabbitmq2 with rabbit@rabbitmq1
    Starting node rabbit@rabbitmq2 ...
    completed with 9 plugins.
    Stopping rabbit application on node rabbit@rabbitmq3 ...
    Clustering node rabbit@rabbitmq3 with rabbit@rabbitmq1
    Starting node rabbit@rabbitmq3 ...
    completed with 9 plugins.

### setup_user.sh
Add user and set permissions.  

    $ ./scripts/setup_user.sh
    Adding user "consumer" ...
    Adding user "publisher" ...
    Setting permissions for user "consumer" in vhost "vhost" ...
    Setting permissions for user "publisher" in vhost "vhost" ...

The user and password are the same!  
Permissions are set for separating read and write access.  

### setup_team.sh
Add to `rabbitmq1` and `rabbitmq2` user and permissions for two teams.  
The idea is to have on every machine a administrator (teamA, teamB) and monitoring user (monitor).  
In addition to this every instance have a user for every service (serviceA, serviceB).  
This should help or frame how two teams could work indepentent or how the instances could be connected.  
Federation or Shovel setups can be find in `setup_federation.sh` or `setup_shovel.sh`.  

    $ ./scripts/setup_team.sh
    Adding user "teamA" ...
    Setting tags for user "teamA" to [administrator] ...
    Adding user "teamB" ...
    Setting tags for user "teamB" to [administrator] ...
    Adding user "monitor" ...
    Setting tags for user "monitor" to [monitoring] ...
    Adding user "monitor" ...
    Setting tags for user "monitor" to [monitoring] ...
    Adding user "serviceA" ...
    Adding user "serviceB" ...
    Adding user "serviceA" ...
    Adding user "serviceB" ...
    Setting permissions for user "teamA" in vhost "vhost" ...
    Setting permissions for user "teamB" in vhost "vhost" ...
    Setting permissions for user "serviceA" in vhost "vhost" ...
    Setting permissions for user "serviceB" in vhost "vhost" ...
    Setting permissions for user "monitor" in vhost "vhost" ...
    Setting permissions for user "serviceA" in vhost "vhost" ...
    Setting permissions for user "serviceB" in vhost "vhost" ...
    Setting permissions for user "monitor" in vhost "vhost" ...

### setup_topology.sh
Add exchanges, queues and bindings.  

    $ ./scripts/setup_topology.sh
    exchange declared
    exchange declared
    queue declared
    queue declared
    binding declared
    binding declared
    binding declared
    binding declared

The topology is a simple event system with a `dead-letter` configuration.  

![Topology](./topology.png?raw=true "Topology")

### setup_policies.sh
Set policies for exchanges and queues.  

    $ ./scripts/setup_policies.sh
    Setting policy "ha-events" for pattern ".\.events" to "{"ha-mode":"all", "ha-sync-mode":"automatic", "dead-letter-exchange":"dlx.events"}" with priority "2" for vhost "vhost" ...
    Setting policy "ha-lazy" for pattern "^(?!amq\.).+" to "{"queue-mode":"lazy", "ha-mode":"all", "ha-sync-mode":"automatic"}" with priority "1" for vhost "vhost" ...

### publish_message.sh
Publish a message.

    $ ./scripts/publish_message.sh
    {"routed":true}
