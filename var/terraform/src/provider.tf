# Configure the RabbitMQ provider
provider "rabbitmq" {
  endpoint = var.rmq_host
  username = var.rmq_username
  password = var.rmq_password
}
