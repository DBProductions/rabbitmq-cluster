#
# Events topology
# topic exchange to receive all events
# stream for all events bind with `#`
# queue for system events bind with `system.*.*`
# queue for update events bind with `*.update.*`
#

resource "rabbitmq_exchange" "events" {
  name  = "events"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "topic"
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_queue" "all_events" {
  name  = "all-events"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable        = true
    arguments_json = "${var.stream-arguments}"
  }
}

resource "rabbitmq_queue" "system_events" {
  name  = "system-events"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_queue" "update_events" {
  name  = "update-events"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_binding" "all_events_binding" {
  source           = "${rabbitmq_exchange.events.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.all_events.name}"
  destination_type = "queue"
  routing_key      = "#" 
}

resource "rabbitmq_binding" "system_events_binding" {
  source           = "${rabbitmq_exchange.events.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.system_events.name}"
  destination_type = "queue"
  routing_key      = "system.*.*" 
}

resource "rabbitmq_binding" "update_events_binding" {
  source           = "${rabbitmq_exchange.events.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.update_events.name}"
  destination_type = "queue"
  routing_key      = "*.update.*" 
}