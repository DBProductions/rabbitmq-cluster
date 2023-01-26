// upstream broker
resource "rabbitmq_federation_upstream" "rabbitmq1" {
  name = "rabbitmq1"
  vhost = rabbitmq_vhost.rmqvhost.name

  definition {
    uri = "amqp://rabbit:rabbit@rabbitmq1:5672/vhost"
    prefetch_count = 1000
    reconnect_delay = 5
    ack_mode = "on-confirm"
    trust_user_id = false
    max_hops = 1
  }
}

resource "rabbitmq_policy" "all_exchanges_policy" {
  name  = "rabbitmq1AllExchanges"
  vhost = rabbitmq_vhost.rmqvhost.name

  policy {
    pattern  = "(^(?!amq.|events)(.+)$)"
    priority = 1
    apply_to = "exchanges"

    definition = {
      federation-upstream = rabbitmq_federation_upstream.rabbitmq1.name
    }
  }
}

resource "rabbitmq_policy" "all_queues_policy" {
  name  = "rabbitmq1AllQueues"
  vhost = rabbitmq_vhost.rmqvhost.name

  policy {
    pattern  = "(.*)"
    priority = 1
    apply_to = "queues"

    definition = {
      federation-upstream = rabbitmq_federation_upstream.rabbitmq1.name
    }
  }
}