# Create same topology for all instances
#
# Request topology
# 
#

resource "rabbitmq_exchange" "requests" {
  name  = "requests"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "topic"
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_queue" "current_requests" {
  name  = "requests.current"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = false
    arguments = {
      "x-queue-type": "quorum",
      "x-dead-letter-exchange": "${rabbitmq_exchange.retry_requests.name}"
    }
  }
  depends_on = [
    rabbitmq_exchange.retry_requests
  ]
}

resource "rabbitmq_binding" "current_requests_binding" {
  source           = "${rabbitmq_exchange.requests.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.current_requests.name}"
  destination_type = "queue"
  routing_key      = "#"
  depends_on = [
    rabbitmq_exchange.requests,
    rabbitmq_queue.current_requests
  ]
}

resource "rabbitmq_exchange" "retry_requests" {
  name  = "retry.requests"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "headers"
    durable     = true
    auto_delete = true
    arguments = {
        "alternate-exchange": rabbitmq_exchange.error_requests.name
    }
  }
  depends_on = [
    rabbitmq_exchange.error_requests
  ]
}

resource "rabbitmq_queue" "delayed_requests" {
  name  = "requests.delayed"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = false
    arguments = {
      "x-queue-type" : "quorum"
    }
  }
}

resource "rabbitmq_policy" "delivery_limit_policy" {
  name  = "delivery-limit"
  vhost = rabbitmq_vhost.rmqvhost.name

  policy {
    pattern  = "(^${rabbitmq_queue.delayed_requests.name}$)"
    priority = 1
    apply_to = "queues"

    definition = {
      delivery-limit = 3
    }
  }

  depends_on = [
    rabbitmq_queue.delayed_requests
  ]
}

resource "rabbitmq_binding" "retry_requests_binding" {
  source           = "${rabbitmq_exchange.retry_requests.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.delayed_requests.name}"
  destination_type = "queue"
  arguments_json = "${var.x-death-arguments}"
  depends_on = [
    rabbitmq_exchange.retry_requests,
    rabbitmq_queue.delayed_requests
  ]
}

resource "rabbitmq_binding" "error_requests_binding" {
  source           = "${rabbitmq_exchange.retry_requests.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.error_requests.name}"
  destination_type = "queue"
  arguments_json = "${var.x-death-limit-arguments}"
  depends_on = [
    rabbitmq_exchange.retry_requests,
    rabbitmq_queue.delayed_requests
  ]
}

resource "rabbitmq_exchange" "error_requests" {
  name  = "error.requests"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "topic"
    durable     = true
    auto_delete = true
  }
}

resource "rabbitmq_queue" "error_requests" {
  name  = "requests.error"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = true
    auto_delete = false
    arguments = {
      "x-queue-type" : "quorum"
    }
  }
}

resource "rabbitmq_binding" "delayed_requests_binding" {
  source           = "${rabbitmq_exchange.error_requests.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.error_requests.name}"
  destination_type = "queue"
  routing_key      = "#"
  depends_on = [
    rabbitmq_exchange.retry_requests,
    rabbitmq_queue.error_requests
  ]
}
