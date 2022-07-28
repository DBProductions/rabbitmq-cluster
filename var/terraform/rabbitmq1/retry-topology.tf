#
# Retry topology
#

resource "rabbitmq_exchange" "system_exchange" {
  name  = "system.events"
  vhost = rabbitmq_vhost.rmqvhost.name

  settings {
    type    = "topic"
    durable = "true"
  }
}

resource "rabbitmq_exchange" "deadletter_exchange" {
  name  = "dlx.events"
  vhost = rabbitmq_vhost.rmqvhost.name

  settings {
    type    = "topic"
    durable = "true"
  }
}

resource "rabbitmq_exchange" "retry_exchange" {
  name  = "dlx.retry"
  vhost = rabbitmq_vhost.rmqvhost.name

  settings {
    type    = "topic"
    durable = "true"
  }
}


resource "rabbitmq_queue" "apievents_queue" {
  name  = "api.events"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = false
  }
}

resource "rabbitmq_queue" "deadevents_queue" {
  name  = "dead.events"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = false
    arguments_json = "${var.msg-ttl-arguments}"
  }
}

# bindings
resource "rabbitmq_binding" "create_exchange_queue_binding" {
  source           = "${rabbitmq_exchange.system_exchange.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.apievents_queue.name}"
  destination_type = "queue"
  routing_key      = "user.create.account"
}

resource "rabbitmq_binding" "update_exchange_queue_binding" {
  source           = "${rabbitmq_exchange.system_exchange.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.apievents_queue.name}"
  destination_type = "queue"
  routing_key      = "user.update.account"
}

resource "rabbitmq_binding" "delete_exchange_queue_binding" {
  source           = "${rabbitmq_exchange.system_exchange.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.apievents_queue.name}"
  destination_type = "queue"
  routing_key      = "user.delete.account"
}

resource "rabbitmq_binding" "dead_exchange_queue_binding" {
  source           = "${rabbitmq_exchange.deadletter_exchange.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.deadevents_queue.name}"
  destination_type = "queue"
  routing_key      = "*.*.*"
}

resource "rabbitmq_binding" "retry_create_exchange_queue_binding" {
  source           = "${rabbitmq_exchange.retry_exchange.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.apievents_queue.name}"
  destination_type = "queue"
  routing_key      = "user.create.account"
}

resource "rabbitmq_binding" "retry_update_exchange_queue_binding" {
  source           = "${rabbitmq_exchange.retry_exchange.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.apievents_queue.name}"
  destination_type = "queue"
  routing_key      = "user.update.account"
}

resource "rabbitmq_binding" "retry_delete_exchange_queue_binding" {
  source           = "${rabbitmq_exchange.retry_exchange.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.apievents_queue.name}"
  destination_type = "queue"
  routing_key      = "user.delete.account"
}

# policies
resource "rabbitmq_policy" "ha_events" {
  name  = "ha-events"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  policy {
    pattern  = "(^api.events$)"
    priority = 2
    apply_to = "queues"

    definition = {
      ha-mode = "all"
      ha-sync-mode = "automatic"
      dead-letter-exchange = "dlx.events"
    }
  }
}

resource "rabbitmq_policy" "ha_retry_events" {
  name  = "ha-retry-events"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  policy {
    pattern  = "(^dead.events$)"
    priority = 3
    apply_to = "queues"

    definition = {
      ha-mode = "all"
      ha-sync-mode = "automatic"
      dead-letter-exchange = "dlx.retry"
    }
  }
}