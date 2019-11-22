# RabbitMQ

This repository gives the possibility to play around with RabbitMQ.  
Should help to understand how Clustering, Federation- and Shovel-Plugin are working.  

# Docker

The `docker-compose` file contains three RabbitMQ services `rabbitmq1`, `rabbitmq2` and `rabbitmq3`.  
Additional Prometheus is defined to monitor the RabbitMQ instances and Grafana to display the stats.  
The used vhost is simple named `vhost`, the admin user (`rabbit`) and password (`rabbit`) are on all nodes the same.  

    $ docker-compose up --build

The management UIs can be found under `http://localhost:15672`, `http://localhost:15673` and `http://localhost:15674`.  
Prometheus is available under `http://localhost:9090/` and Grafana serves here `http://localhost:3000/`.  
For Grafana the `admin` password is simple `password`. Some community built dashboards are included.  

Enabled plugins:  
 - rabbitmq_mqtt  
 - rabbitmq_federation  
 - rabbitmq_federation_management  
 - rabbitmq_stomp  
 - rabbitmq_shovel  
 - rabbitmq_shovel_management  
 - rabbitmq_prometheus  

# Scripts

A collection of scripts using `rabbitmqadmin`, `rabbitmqctl` and `curl` to create Cluster, Upstreams, Exchanges, Queues, Bindings, Policies, User and publish messages.

### setup_federation.sh
Instead of joining a cluster, we have three broker and want to connect them.  
On `rabbitmq1` we create a exchange, two queues, a binding and add two upstreams.  
`rabbitmq2` and `rabbitmq3` we create a user used to connect with the upstreams.  
This upstreams are connecting to `rabbitmq2` and `rabbitmq3` after the policies are applied on `rabbitmq1`.  
The federated exchange links to the upstream exchange, published messages to `rabbitmq2` will be copied to `rabbitmq1`.
The federated queue links to the upstream queue and will retrieve messages from `rabbitmq3` when a consumer is connected on `rabbitmq1`.  
The running federation links can called over the API: `http://localhost:15672/api/federation-links`

    $ ./scripts/setup_federation.sh
    Adding user "federal" ...
    Setting permissions for user "federal" in vhost "vhost" ...
    Adding user "federal" ...
    Setting permissions for user "federal" in vhost "vhost" ...
    exchange declared
    queue declared
    queue declared
    binding declared
    Setting runtime parameter "federation-upstream" for component "rabbitmq2" to "{"uri": "amqp://federal:federal@rabbitmq2:5672/vhost", "ack-mode":"on-confirm", "reconnect-delay": 1, "prefetch-count": 200, "max-hops": 1}" in vhost "vhost" ...
    Setting runtime parameter "federation-upstream-set" for component "rabbitmq2" to "[{"upstream": "rabbitmq2"}]" in vhost "vhost" ...
    Setting runtime parameter "federation-upstream" for component "rabbitmq3" to "{"uri": "amqp://federal:federal@rabbitmq3:5672/vhost", "ack-mode":"on-confirm", "reconnect-delay": 1, "prefetch-count": 200}" in vhost "vhost" ...
    Setting runtime parameter "federation-upstream-set" for component "rabbitmq3" to "[{"upstream": "rabbitmq3"}]" in vhost "vhost" ...
    Setting policy "federation_rabbitmq2" for pattern "rabbitmq2.federated.*" to "{"federation-upstream-set": "rabbitmq2"}" with priority "0" for vhost "vhost" ...
    Setting policy "ha-federation" for pattern "^federation:*" to "{"ha-mode": "all"}" with priority "0" for vhost "vhost" ...
    Setting policy "federation_rabbitmq3" for pattern "federated.*" to "{"federation-upstream-set": "rabbitmq3"}" with priority "0" for vhost "vhost" ...
    Setting policy "ha-federation" for pattern "^federation:*" to "{"ha-mode": "all"}" with priority "0" for vhost "vhost" ...

### setup_shovel.sh
Instead of joining a cluster, we have three broker and want to connect them.  
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

### setup_team.sh
Add to `rabbitmq1` and `rabbitmq2` user and permissions for two teams.  
The idea is to have on every machine a administrator (teamA, teamB) and monitoring user (monitor).  
In addition to this every instance have a user for every service (serviceA, serviceB).  
The two instances are connected with a federation upstream where `rabbitmq1` receives copies from `rabbitmq2`.  
The `shovel` queue on `rabbitmq1` shovels messages to the exchange `rabbitmq1.shovel` on `rabbitmq2`.  

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
    exchange declared
    queue declared
    binding declared
    Setting runtime parameter "federation-upstream" for component "rabbitmq2" to "{"max-hops": 1, "uri": "amqp://teamB:teamB@rabbitmq2:5672/vhost", "ack-mode":"on-publish"}" in vhost "vhost" ...
    Setting runtime parameter "federation-upstream-set" for component "rabbitmq2" to "[{"upstream": "rabbitmq2"}]" in vhost "vhost" ...
    Setting policy "federation_rabbitmq2" for pattern "rabbitmq2.federated.*" to "{"federation-upstream-set": "rabbitmq2"}" with priority "0" for vhost "vhost" ...
    Setting policy "ha-federation" for pattern "^federation:*" to "{"ha-mode": "all"}" with priority "0" for vhost "vhost" ...
    queue declared
    exchange declared
    queue declared
    binding declared
    Setting runtime parameter "shovel" for component "rabbitmq2" to "{"src-protocol": "amqp091", "src-uri": "amqp://teamA:teamA@rabbitmq1:5672/vhost", "src-queue": "shovel", "dest-protocol": "amqp091", "dest-uri": "amqp://teamB:teamB@rabbitmq2:5672/vhost", "dest-exchange": "rabbitmq1.shovel"}" in vhost "vhost" ...

## setup_cluster.sh 
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

### setup_retry_dlx_topology.sh
Add exchanges, queues and bindings to create a DLX retry topology.  
When a message gets rejected and a dead letter exchange is defined for the queue the message is forwarded to the defined exchange.  
The dead letter exchange is bind to a queue where all rejected messages arrive, this queue have a `x-message-ttl` defined.  
Additional to the TTL the queue have also a dead-letter-exchange defined, when the TTL is over the messages are forwarded to this exchange.  
From the second exchange the messages are routed again to the queue where they have been rejected.  

For this retry topology we need two additional exchanges and a queue to let the messages wait before they get routed again.  
TTL is a constant delay for all messages to retry and RabbitMQ counts each time a message is dead-lettered and set it as count field on the `x-death` header.  

    $ ./scripts/setup_retry_topology.sh
    exchange declared
    exchange declared
    exchange declared
    queue declared
    queue declared
    binding declared
    binding declared
    binding declared
    binding declared
    binding declared
    binding declared
    binding declared
    Setting policy "ha-events" for pattern ".\.events" to "{"ha-mode":"all", "ha-sync-mode":"automatic", "dead-letter-exchange":"dlx.events"}" with priority "2" for vhost "vhost" ...
    Setting policy "ha-retry-events" for pattern "dead-events" to "{"ha-mode":"all", "ha-sync-mode":"automatic", "dead-letter-exchange":"dlx.retry"}" with priority "2" for vhost "vhost" ...

![Reject DLX Retry](./retry-dlx.png?raw=true "Reject DLX Retry")

### setup_policies.sh
Set policies for exchanges and queues.  

    $ ./scripts/setup_policies.sh
    Setting policy "ha-events" for pattern ".\.events" to "{"ha-mode":"all", "ha-sync-mode":"automatic", "dead-letter-exchange":"dlx.events"}" with priority "2" for vhost "vhost" ...
    Setting policy "ha-lazy" for pattern "^(?!amq\.).+" to "{"queue-mode":"lazy", "ha-mode":"all", "ha-sync-mode":"automatic"}" with priority "1" for vhost "vhost" ...

### publish_message.sh
Publish a message.

    $ ./scripts/publish_message.sh
    {"routed":true}
