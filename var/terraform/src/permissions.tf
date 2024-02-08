resource "rabbitmq_permissions" "team_perm" {
  user  = "${rabbitmq_user.team.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }
  
  depends_on = [
    rabbitmq_user.team
  ]
}

resource "rabbitmq_permissions" "federation_perm" {
  user  = "${rabbitmq_user.federation.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = "^ExchangeFederated$|^federation: ExchangeFederated -> rabbit@rabbitmq1.*"
    write     = "^federation: ExchangeFederated -> rabbit@rabbitmq1.*"
    read      = "^ExchangeFederated$|^federation: ExchangeFederated -> rabbit@rabbitmq1.*"
  }

  depends_on = [
    rabbitmq_user.federation
  ]
}

resource "rabbitmq_permissions" "publisher_perm" {
  user  = "${rabbitmq_user.publisher.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = ""
    write     = ".*"
    read      = ""
  }

  depends_on = [
    rabbitmq_user.publisher
  ]
}

resource "rabbitmq_permissions" "consumer_perm" {
  user  = "${rabbitmq_user.consumer.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = ""
    write     = ""
    read      = ".*"
  }

  depends_on = [
    rabbitmq_user.consumer
  ]
}

resource "rabbitmq_permissions" "monitor_perm" {
  user  = "${rabbitmq_user.monitor.name}"
  vhost = "${rabbitmq_vhost.rmqvhost.name}"

  permissions {
    configure = ""
    write     = ""
    read      = ""
  }
  
  depends_on = [
    rabbitmq_user.monitor
  ]
}