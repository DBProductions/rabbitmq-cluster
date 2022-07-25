# Create a virtual host
resource "rabbitmq_vhost" "rmqvhost" {
  name = "vhost"
}

# Create same topology for all instances
resource "rabbitmq_exchange" "frontEx" {
  name  = "frontEx-${var.rmq_instance_name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "topic"
    durable     = false
    auto_delete = true
  }
}

resource "rabbitmq_exchange" "test" {
  name  = "test"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    type        = "headers"
    durable     = false
    auto_delete = true
  }
}

resource "rabbitmq_queue" "test" {
  name  = "test"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  settings {
    durable     = false
    auto_delete = true
  }
}

resource "rabbitmq_binding" "ex2ex" {
  source           = "${rabbitmq_exchange.frontEx.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.test.name}"
  destination_type = "exchange"
}

resource "rabbitmq_binding" "test" {
  source           = "${rabbitmq_exchange.test.name}"
  vhost            = "${rabbitmq_vhost.rmqvhost.name}"
  destination      = "${rabbitmq_queue.test.name}"
  destination_type = "queue"
  routing_key      = "#"
  arguments = "${var.binding-arguments}"
}
