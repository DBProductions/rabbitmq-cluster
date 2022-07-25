resource "rabbitmq_permissions" "team_perm" {
  user  = "${rabbitmq_user.team.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }
}

resource "rabbitmq_permissions" "publisher_perm" {
  user  = "${rabbitmq_user.publisher.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = ""
    write     = ".*"
    read      = ""
  }
}

resource "rabbitmq_permissions" "consumer_perm" {
  user  = "${rabbitmq_user.consumer.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = ""
    write     = ""
    read      = ".*"
  }
}

resource "rabbitmq_permissions" "monitor_perm" {
  user  = "${rabbitmq_user.monitor.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = ""
    write     = ""
    read      = ""
  }
}