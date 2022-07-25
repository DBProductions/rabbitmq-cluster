# RabbitMQ

This repository gives the possibility to play around with RabbitMQ 3.9.20.  
Should help to understand how Clustering, Federation- and Shovel-Plugin are working.  

# Docker

The `docker-compose` file contains three RabbitMQ services `rabbitmq1`, `rabbitmq2` and `rabbitmq3`.  
Additional Prometheus is defined to monitor the RabbitMQ instances and Grafana to display the stats.  
The used vhost is simple named `vhost`, the admin user (`rabbit`) and password (`rabbit`) are on all nodes the same.  

    $ docker-compose up --build

This will start all services defined in the compose file.

The following services are defined:
 - rabbitmq1
 - rabbitmq2
 - rabbitmq3
 - prometheus
 - grafana

In case you only want to have two instance without monitoring it can be started like this.

    $ docker-compose up rabbitmq1 rabbitmq2 --build

Enabled plugins:  
 - rabbitmq_mqtt  
 - rabbitmq_federation  
 - rabbitmq_federation_management  
 - rabbitmq_stomp  
 - rabbitmq_shovel  
 - rabbitmq_shovel_management  
 - rabbitmq_prometheus  
 - rabbitmq_stream  

The management UIs can be found under `http://localhost:15672`, `http://localhost:15673` and `http://localhost:15674`.  
Prometheus is available under `http://localhost:9090/` and Grafana serves here `http://localhost:3000/`.  
For Grafana the `admin` password is simple `password`. Some community built dashboards are included.  

When you face problems with the Grafana login you can set a password like this.

    $ docker exec -it <name of grafana container> grafana-cli admin reset-admin-password <fill in password>

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

### setup_shovel.sh
Instead of joining a cluster, we have three broker and want to connect them.  
On all three broker we create a queue named `shovel`, on `rabbitmq1` and `rabbitmq2` we create a dynamic shovel.  
`rabbitmq2` have an additional exchange named `rabbitmq1.shovel` bind to the `shovel` queue on `rabbitmq2`.  

The queue on `rabbitmq1` is the source for the exchange on `rabbitmq2` and the queue on `rabbitmq2` is then the source for the queue on `rabbitmq3`.  
Every message published to `shovel` on `rabbitmq1` is shovelled to the exchange `rabbitmq1.shovel` on `rabbitmq2` then finally shovelled from the `shovel` queue on `rabbitmq2` to the `shovel` queue on `rabbitmq3`.

    $ ./scripts/setup_shovel.sh

### setup_team.sh
Add to `rabbitmq1` and `rabbitmq2` user and permissions for two teams.  
The idea is to have on every machine a administrator (teamA, teamB) and monitoring user (monitor).  
In addition to this every instance have a user for every service (serviceA, serviceB).  
The two instances are connected with a federation upstream where `rabbitmq1` receives copies from `rabbitmq2`.  
The `shovel` queue on `rabbitmq1` shovels messages to the exchange `rabbitmq1.shovel` on `rabbitmq2`.  

    $ ./scripts/setup_team.sh

### backup_instance.sh and import_definitions.sh
To keep the changes to the single instances, it's simple to export the current definitions.  
This definitions can be adjusted in JSON format and imported again.

    $ ./scripts/backup_instance.sh
    Exported definitions for localhost to "./export/rabbitmq1.json"  
    ...

    $ ./scripts/import_definitions.sh
    Uploaded definitions from "localhost" to ./export/rabbitmq1.json. The import process may take some time. Consult server logs to track progress.  
    ...

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

### setup_retry_dlx_topology.sh
Add exchanges, queues and bindings to create a DLX retry topology.  
When a message gets rejected and a dead letter exchange is defined for the queue the message is forwarded to the defined exchange.  
The dead letter exchange is bind to a queue where all rejected messages arrive, this queue have a `x-message-ttl` defined.  
Additional to the TTL the queue have also a dead-letter-exchange defined, when the TTL is over the messages are forwarded to this exchange.  
From the second exchange the messages are routed again to the queue where they have been rejected.  

For this retry topology we need two additional exchanges and a queue to let the messages wait before they get routed again.  
TTL is a constant delay for all messages to retry and RabbitMQ counts each time a message is dead-lettered and set it as count field on the `x-death` header.  

    $ ./scripts/setup_retry_dlx_topology.sh

![Reject DLX Retry](./retry-dlx.png?raw=true "Reject DLX Retry")

### setup_policies.sh
Set policies for exchanges and queues.  

    $ ./scripts/setup_policies.sh

### publish_message.sh
Publish a message.

    $ ./scripts/publish_message.sh
    {"routed":true}

## Terraform/Terragrunt

Plan, apply and destroy the Terraform scripts to the specific instance.  

    $ terragrunt plan --terragrunt-working-dir ./var/terraform/rabbitmq1

    $ terragrunt apply --terragrunt-working-dir ./var/terraform/rabbitmq1 -auto-approve
    $ terragrunt apply --terragrunt-working-dir ./var/terraform/rabbitmq2 -auto-approve
    $ terragrunt apply --terragrunt-working-dir ./var/terraform/rabbitmq3 -auto-approve

    $ terragrunt destroy --terragrunt-working-dir ./var/terraform/rabbitmq1 -auto-approve

Every instance get the same setup the differences are defined in the specific `terragrunt.hcl` files or additional Terraform scripts.

## rabbitmq-perf-test

    wget https://github.com/rabbitmq/rabbitmq-perf-test/releases/download/v2.15.0/rabbitmq-perf-test-2.15.0-bin.zip
    unzip rabbitmq-perf-test-2.15.0-bin.zip
    cd rabbitmq-perf-test-2.15.0/

Runs it against the cluster.

    bin/runjava com.rabbitmq.perf.PerfTest -h amqp://rabbit:rabbit@localhost:5672/vhost

Runs a single publisher and two consumers using a queue named `perf-test`.

    bin/runjava com.rabbitmq.perf.PerfTest -x 1 -y 2 -u "perf-test" -h amqp://rabbit:rabbit@localhost:5672/vhost

With a benchmark specification file `publish-consume-spec.js` this command creates `publish-consume-result.js`.  
This file can be used to display a graph on a HTML page. [More details](https://github.com/rabbitmq/rabbitmq-perf-test/blob/master/html/README.md)

    bin/runjava com.rabbitmq.perf.PerfTestMulti ../var/rabbitmq/benchmarks/publish-consume-spec.js ../var/rabbitmq/results/publish-consume-result.js

To see the result, change to the results directory and start a web server.

    cd ../var/rabbitmq/results/
    python3 -m http.server 8888

## Feedback
Star this repo if you found it useful. Use the github issue tracker to give feedback on this repo.