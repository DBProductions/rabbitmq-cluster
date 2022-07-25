#
# Filter topology based on two exchanges.
# unfiltered as topic exchange takes all messages and send them the unfiltered-log queue
# eventrouter as exchange is bind to the unfiltered exchange
# now we can add queues and bindings to the eventrouter to filter bbased on headers
#

resource "rabbitmq_exchange" "unfiltered" {
  name  = "unfiltered"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "topic"
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_exchange" "eventrouter" {
  name  = "eventrouter"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "headers"
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_queue" "unfiltered_log" {
  name  = "unfiltered-log"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_queue" "filtered_1" {
  name  = "filtered-1"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_queue" "filtered_2" {
  name  = "filtered-2"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_queue" "filtered_all" {
  name  = "filtered-all"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_binding" "unfiltered_filter_binding" {
  source           = "${rabbitmq_exchange.unfiltered.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_exchange.eventrouter.name}"
  destination_type = "exchange"
  routing_key      = "#"
}

resource "rabbitmq_binding" "unfiltered_log_binding" {
  source           = "${rabbitmq_exchange.unfiltered.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.unfiltered_log.name}"
  destination_type = "queue"
  routing_key      = "#"
}

resource "rabbitmq_binding" "filtered_1_binding" {
  source           = "${rabbitmq_exchange.eventrouter.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.filtered_1.name}"
  destination_type = "queue"
  arguments = "${var.binding-arguments-1}"
}

resource "rabbitmq_binding" "filtered_2_binding" {
  source           = "${rabbitmq_exchange.eventrouter.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.filtered_2.name}"
  destination_type = "queue"
  arguments = "${var.binding-arguments-2}"
}

resource "rabbitmq_binding" "filtered_all_binding" {
  source           = "${rabbitmq_exchange.eventrouter.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.filtered_all.name}"
  destination_type = "queue"
  arguments = "${var.binding-arguments-all}"
}