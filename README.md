# RabbitMQ

This repository provides you with the opportunity to experiment with RabbitMQ 3.12.0 and gain a better understanding of how Clustering, Federation, and Shovel plugins function.  

# Docker

The `docker-compose` file consists of three RabbitMQ services named `rabbitmq1`, `rabbitmq2`, and `rabbitmq3`. Additionally, Prometheus is configured to monitor the RabbitMQ instances, and Grafana is used to display the statistics. The virtual host used is simply named `vhost`, and the admin user (`rabbit`) and password (`rabbit`) are the same on all nodes.  

    $ docker-compose up --build

This will start all services defined in the compose file.

The following services are defined:
 - rabbitmq1
 - rabbitmq2
 - rabbitmq3
 - prometheus
 - grafana

If you only want to have two instances without monitoring, you can start them using the provided configuration like this.

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

The management UIs can be found under:
- `http://localhost:15672`
- `http://localhost:15673`
- `http://localhost:15674`  

## Monitoring
Prometheus is available under `http://localhost:9090/` and Grafana serves here `http://localhost:3000/`.  
For Grafana the `admin` password is simple `password`. Some community built dashboards are included.  

When you face problems with the Grafana login you can set a password like this.

    $ docker exec -it <name of grafana container> grafana-cli admin reset-admin-password <fill in password>

# Scripts

A collection of scripts using `rabbitmqadmin`, `rabbitmqctl` and `curl` to create Cluster, Upstreams, Exchanges, Queues, Bindings, Policies, User and publish messages.

<details>
  <summary> backup_instance.sh and import_definitions.sh</summary>
  To keep the changes to the single instances, it's simple to export the current definitions. This definitions can be adjusted in JSON format and imported again.

    $ ./scripts/backup_instance.sh
    Exported definitions for localhost to "./export/rabbitmq1.json"  
    ...

    $ ./scripts/import_definitions.sh
    Uploaded definitions from "localhost" to ./export/rabbitmq1.json. The import process may take some time. Consult server logs to track progress.  
    ...
</details>

<details>
  <summary> setup_federation.sh</summary>
  Instead of joining a cluster, we have three broker and want to connect them.  
  On `rabbitmq1` we create an exchange, two queues, a binding and add two upstreams.  
  Creates a user on `rabbitmq2` and `rabbitmq3` to connect with the upstreams.  
  This upstreams are connecting to `rabbitmq2` and `rabbitmq3` after the policies are applied on `rabbitmq1`.  

  The federated exchange links to the upstream exchange, published messages to `rabbitmq2` will be copied to `rabbitmq1`.  
  The federated queue links to the upstream queue and will retrieve messages from `rabbitmq3` when a consumer is connected on `rabbitmq1`.  
  The running federation links can called over the API: `http://localhost:15672/api/federation-links`

    $ ./scripts/setup_federation.sh
</details>

<details>
  <summary> setup_shovel.sh</summary>
  Instead of joining a cluster, we have three broker and want to connect them.  
  On all three broker we create a queue named `shovel`, on `rabbitmq1` and `rabbitmq2` we create a dynamic shovel.  
  `rabbitmq2` have an additional exchange named `rabbitmq1.shovel` bind to the `shovel` queue on `rabbitmq2`.  

  The queue on `rabbitmq1` is the source for the exchange on `rabbitmq2` and the queue on `rabbitmq2` is then the source for the queue on `rabbitmq3`.  
  Every message published to `shovel` on `rabbitmq1` is shovelled to the exchange `rabbitmq1.shovel` on `rabbitmq2` then finally shovelled from the `shovel` queue on `rabbitmq2` to the `shovel` queue on `rabbitmq3`.

    $ ./scripts/setup_shovel.sh
</details>

<details>
  <summary> setup_team.sh</summary>
  Add to `rabbitmq1` and `rabbitmq2` user and permissions for two teams.  
  The idea is to have on every machine a administrator (teamA, teamB) and monitoring user (monitor).  
  In addition to this every instance have a user for every service (serviceA, serviceB).  
  The two instances are connected with a federation upstream where `rabbitmq1` receives copies from `rabbitmq2`.  
  The `shovel` queue on `rabbitmq1` shovels messages to the exchange `rabbitmq1.shovel` on `rabbitmq2`.  

    $ ./scripts/setup_team.sh
</details>

<details>
  <summary> setup_cluster.sh</summary>
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
</details>

<details>
  <summary> setup_retry_dlx_topology.sh</summary>
  Add exchanges, queues and bindings to create a DLX retry topology.  
  When a message gets rejected and a dead letter exchange is defined for the queue the message is forwarded to the defined exchange.  
  The dead letter exchange is bind to a queue where all rejected messages arrive, this queue have a `x-message-ttl` defined.  
  Additional to the TTL the queue have also a dead-letter-exchange defined, when the TTL is over the messages are forwarded to this exchange.  
  From the second exchange the messages are routed again to the queue where they have been rejected.  

  For this retry topology we need two additional exchanges and a queue to let the messages wait before they get routed again.  
  TTL is a constant delay for all messages to retry and RabbitMQ counts each time a message is dead-lettered and set it as count field on the `x-death` header.  

    $ ./scripts/setup_retry_dlx_topology.sh

```mermaid
  flowchart LR;
      A{events} --> |user.create.account\nuser.update.account\nuser.delete.account| B(api.events);
      B --> |dead-letter-exchange| C{dlx.events};
      C --> |*.*.*| D(dead.events)
      D --> |dead-letter-exchange, ttl| E{dlx.retry};
      E --> |user.create.account\nuser.update.account\nuser.delete.account| B;
```
</details>
  
# Terraform/Terragrunt

Directory structure organised for every instance to have an own folder with specific Terraform scripts. The scripts in `src` are executed on every instance like a common configuration.
```
- /var/terraform
  - /rabbitmq1
  - /rabbitmq2
  - /rabbitmq3
  - /src
```

Plan, apply and destroy the Terraform scripts to the specific instance.  

    $ terragrunt plan --terragrunt-working-dir ./var/terraform/rabbitmq1

    $ terragrunt apply --terragrunt-working-dir ./var/terraform/rabbitmq1 -auto-approve
    $ terragrunt apply --terragrunt-working-dir ./var/terraform/rabbitmq2 -auto-approve
    $ terragrunt apply --terragrunt-working-dir ./var/terraform/rabbitmq3 -auto-approve

    $ terragrunt run-all apply --terragrunt-working-dir ./var/terraform/ -auto-approve

    $ terragrunt destroy --terragrunt-working-dir ./var/terraform/rabbitmq1 -auto-approve

Every instance get the same setup, differences are defined in the specific `terragrunt.hcl` file or additional Terraform scripts.

The setup includes an `events` topic exchange for routing messages based on the routing key.  
The routing keys follow the `subject.verb.object` definition, allowing flexibility in defining queues and bindings as required. There are two queues, `all-events` and `last-events`, both of which are of type `stream` to store the messages. The `last-events` queue has a defined `x-max-age` of five minutes to keep the messages short-lived, while the `all-events` queue stores all events.

```mermaid
  flowchart LR
    A{events} -->|#| B(all-events)
    A -->|#| C(last-events)
    A --> |system.*.*| D(system-events)
    A -->|*.create.*| E(create-events)
    A -->|*.update.*| F(update-events)
```

The instance `rabbitmq1` have some additional Terrafrom scripts included to create topologies.

Filtering with two exchanges, a `topic` exchange in front of an `header` exchange.
```mermaid
  flowchart LR
    A{unfiltered} --> |#| B{eventrouter}
    A --> |#| C(unfiltered-log)
    B --> |x-match=any\ncountry=1\nrid=1| D(filtered-1)
    B --> |x-match=any\ncountry=2\nrid=2| E(filtered-2)
```

The instance `rabbbitmq2` have no additional Terraform scripts but `rabbitmq3` try to federate all exchanges and queues with `rabbitmq1`. Every exchanges and queue created on instance `rabbitmq3` will create a connection and topology on `rabbitmq1`.

## rabbitmq-perf-test

    wget https://github.com/rabbitmq/rabbitmq-perf-test/releases/download/v2.18.0/rabbitmq-perf-test-2.18.0-bin.zip
    unzip rabbitmq-perf-test-2.18.0-bin.zip
    cd rabbitmq-perf-test-2.18.0/

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

## stream-perf-test

    wget https://github.com/rabbitmq/rabbitmq-java-tools-binaries-dev/releases/download/v-stream-perf-test-latest/stream-perf-test-latest.jar
    java -jar stream-perf-test-latest.jar --delete-streams --uris rabbitmq-stream://rabbit:rabbit@localhost:5552/vhost

## Feedback
Star this repo if you found it useful. Use the github issue tracker to give feedback on this repo.