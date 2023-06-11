#
# Legacy queue shovels messages to another new queue on the same broker.
# Change consumer to the new queue and publisher afterwards to prevent losing messages.
# Afterwards the legacy queue can be safely removed.
#

resource "rabbitmq_queue" "legacy" {
    name = "legacy_queue"
    vhost = rabbitmq_vhost.rmqvhost.name
    settings {
        durable = false
        auto_delete = true
    }
}

resource "rabbitmq_queue" "new" {
    name = "new_queue"
    vhost = rabbitmq_vhost.rmqvhost.name
    settings {
        durable     = true
        auto_delete = false
        arguments = {
            "x-queue-type" : "quorum",
        }
    }
}

resource "rabbitmq_shovel" "queue_shovel" {
    name = "queueShovel"
    vhost = rabbitmq_vhost.rmqvhost.name
    info {
        source_uri = "amqp://rabbit:rabbit@rabbitmq1:5672/vhost"
        source_queue = "${rabbitmq_queue.legacy.name}"
        destination_add_forward_headers = true
        destination_uri = "amqp://rabbit:rabbit@rabbitmq1:5672/vhost"
        destination_queue = "${rabbitmq_queue.new.name}"
    }
}