#
# Exchange federation (rabbitmq2 --> rabbitmq1)
# rabbitmq1: downStreamExchange -- # --> downStreamQueue
# rabbitmq1: rabbbitmq2 as upstream for rabbitmq1
# rabbbitmq2: downStreamExchange
#

resource "rabbitmq_exchange" "downstream_exchange" {
  name  = "downStreamExchange"
  vhost = rabbitmq_vhost.rmqvhost.name

  settings {
    type    = "topic"
    durable = "true"
  }
}

resource "rabbitmq_queue" "downstream_queue" {
  name  = "downStreamQueue"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_binding" "downstream_exchange_queue_binding" {
  source           = "${rabbitmq_exchange.downstream_exchange.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.downstream_queue.name}"
  destination_type = "queue"
  routing_key      = "#"
}

// upstream broker
resource "rabbitmq_federation_upstream" "rabbitmq2" {
  name = "rabbitmq2"
  vhost = rabbitmq_vhost.rmqvhost.name

  definition {
    uri = "amqp://rabbit:rabbit@rabbitmq2:5672/vhost"
    prefetch_count = 1000
    reconnect_delay = 5
    ack_mode = "on-confirm"
    trust_user_id = false
    max_hops = 1
  }
}

resource "rabbitmq_policy" "exchange_policy" {
  name  = "rabbitmq2Exchange"
  vhost = rabbitmq_vhost.rmqvhost.name

  policy {
    pattern  = "(^${rabbitmq_exchange.downstream_exchange.name}$)"
    priority = 1
    apply_to = "exchanges"

    definition = {
      federation-upstream = rabbitmq_federation_upstream.rabbitmq2.name
    }
  }
}