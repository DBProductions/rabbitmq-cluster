#
# Filter topology based on two exchanges.
# Unfiltered as topic exchange takes all messages and send them the unfiltered-log queue
# Eventrouter as exchange is bind to the unfiltered exchange
# now we can add queues and bindings to the Eventrouter to filter based on headers
#

resource "rabbitmq_exchange" "unfiltered" {
  name  = "Unfiltered"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "topic"
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_exchange" "eventrouter" {
  name  = "Eventrouter"
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
    durable     = false
    auto_delete = true
  }
}

resource "rabbitmq_queue" "filtered_1" {
  name  = "filtered-1"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = false
    auto_delete = true
  }
}

resource "rabbitmq_queue" "filtered_2" {
  name  = "filtered-2"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = false
    auto_delete = true
  }
}

resource "rabbitmq_queue" "filtered_all" {
  name  = "filtered-all"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = false
    auto_delete = true
  }
}

resource "rabbitmq_binding" "unfiltered_filter_binding" {
  source           = "${rabbitmq_exchange.unfiltered.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_exchange.eventrouter.name}"
  destination_type = "exchange"
  routing_key      = "#"
  depends_on = [
    rabbitmq_exchange.unfiltered,
    rabbitmq_exchange.eventrouter
  ]
}

resource "rabbitmq_binding" "unfiltered_log_binding" {
  source           = "${rabbitmq_exchange.unfiltered.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.unfiltered_log.name}"
  destination_type = "queue"
  routing_key      = "#"
  depends_on = [
    rabbitmq_exchange.unfiltered,
    rabbitmq_queue.unfiltered_log
  ]
}

resource "rabbitmq_binding" "filtered_1_binding" {
  source           = "${rabbitmq_exchange.eventrouter.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.filtered_1.name}"
  destination_type = "queue"
  arguments = "${var.binding-arguments-1}"
  depends_on = [
    rabbitmq_exchange.eventrouter,
    rabbitmq_queue.filtered_1
  ]
}

resource "rabbitmq_binding" "filtered_2_binding" {
  source           = "${rabbitmq_exchange.eventrouter.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.filtered_2.name}"
  destination_type = "queue"
  arguments = "${var.binding-arguments-2}"
  depends_on = [
    rabbitmq_exchange.eventrouter,
    rabbitmq_queue.filtered_2
  ]
}

resource "rabbitmq_binding" "filtered_all_binding" {
  source           = "${rabbitmq_exchange.eventrouter.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.filtered_all.name}"
  destination_type = "queue"
  arguments = "${var.binding-arguments-all}"
  depends_on = [
    rabbitmq_exchange.eventrouter,
    rabbitmq_queue.filtered_all
  ]
}