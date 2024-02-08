#
# Exchange federation (rabbitmq2 --> rabbitmq1)
# rabbitmq1: ExchangeFederated -- # --> downStreamQueue
# rabbitmq1: rabbbitmq2 as upstream for rabbitmq1
# rabbbitmq2: ExchangeFederated
#

resource "rabbitmq_exchange" "downstream_exchange" {
  name  = "ExchangeFederated"
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
  depends_on = [
    rabbitmq_exchange.downstream_exchange,
    rabbitmq_queue.downstream_queue
  ]
}

// upstream broker
resource "rabbitmq_federation_upstream" "rabbitmq2_upstream" {
  name = "rabbitmq2"
  vhost = rabbitmq_vhost.rmqvhost.name
  definition {
    uri = "amqp://${rabbitmq_user.federation.name}:${rabbitmq_user.federation.password}@rabbitmq2:5672/vhost"
    prefetch_count = 1000
    reconnect_delay = 5
    ack_mode = "on-confirm"
    trust_user_id = false
    max_hops = 1
  }
  depends_on = [
    rabbitmq_user.federation
  ]
}

resource "rabbitmq_policy" "exchange_policy" {
  name  = "RabbitMQ2"
  vhost = rabbitmq_vhost.rmqvhost.name

  policy {
    pattern  = "(^${rabbitmq_exchange.downstream_exchange.name}$)"
    priority = 1
    apply_to = "exchanges"

    definition = {
      federation-upstream = rabbitmq_federation_upstream.rabbitmq2_upstream.name
    }
  }

  depends_on = [
    rabbitmq_federation_upstream.rabbitmq2_upstream
  ]
}