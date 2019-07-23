# RabbitMQ

This repository gives the possibility to play around with RabbitMQ.  
Should helps to understand how clustering works.  

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

A collection of scripts use `rabbitmqadmin`, `rabbitmqctl` and `curl` to create Cluster, Upstreams, Exchanges, Queues, Bindings, Policies, User and publish a message.

### setup_cluster.sh 
Let `rabbitmq2` and `rabbitmq3` join `rabbitmq1` as cluster.  

    $ ./scripts/setup_cluster.sh
    Stopping rabbit application on node rabbit@rabbitmq2 ...
    Clustering node rabbit@rabbitmq2 with rabbit@rabbitmq1
    Starting node rabbit@rabbitmq2 ...
    completed with 9 plugins.
    Stopping rabbit application on node rabbit@rabbitmq3 ...
    Clustering node rabbit@rabbitmq3 with rabbit@rabbitmq1
    Starting node rabbit@rabbitmq3 ...
    completed with 9 plugins.

### setup_federation.sh
Instead of joining a cluster, here we have three broker which are connected.  
On `rabbitmq1` we create two exchanges, a queue and two bindings then add two upstreams.  
This upstreams are connecting to `rabbitmq2` and `rabbitmq3` after the policies are applied.  
`rabbitmq2` and `rabbitmq3` gets exchanges created and messages are also send to the exchanges on `rabbitmq1`.

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
Every message published to `shovel` on `rabbitmq1` is shovelled to the exchange `rabbitmq1.shovel` on `rabbitmq2` then finally shovelled from the `shovel` queue on `rabbitmq2` to `rabbitmq3`.

    $ ./scripts/setup_shovel.sh
    queue declared
    exchange declared
    queue declared
    binding declared
    queue declared
    Setting runtime parameter "shovel" for component "rabbitmq2" to "{"src-protocol": "amqp091", "src-uri": "amqp://rabbit:rabbit@rabbitmq1:5672/vhost", "src-queue": "shovel", "dest-protocol": "amqp091", "dest-uri": "amqp://rabbit:rabbit@rabbitmq2:5672/vhost", "dest-exchange": "rabbitmq1.shovel"}" in vhost "vhost" ...
    Setting runtime parameter "shovel" for component "rabbitmq3" to "{"src-protocol": "amqp091", "src-uri": "amqp://rabbit:rabbit@rabbitmq2:5672/vhost", "src-queue": "shovel", "dest-protocol": "amqp091", "dest-uri": "amqp://rabbit:rabbit@rabbitmq3:5672/vhost", "dest-queue": "shovel"}" in vhost "vhost" ...

### setup_user.sh
Add user and set permissions.  

    $ ./scripts/setup_user.sh
    Adding user "consumer" ...
    Adding user "publisher" ...
    Setting permissions for user "consumer" in vhost "vhost" ...
    Setting permissions for user "publisher" in vhost "vhost" ...

The user and password are the same!  

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
