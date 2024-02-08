resource "rabbitmq_user" "team" {
  name     = var.team_username
  password = var.team_password
  tags     = ["administrator", "management"]
}

resource "rabbitmq_user" "federation" {
  name     = var.federation_username
  password = var.federation_password
  tags     = ["federation"]
}

resource "rabbitmq_user" "publisher" {
  name     = "publisher"
  password = "publisher"
  tags     = ["service"]
}

resource "rabbitmq_user" "consumer" {
  name     = "consumer"
  password = "consumer"
  tags     = ["service"]
}

resource "rabbitmq_user" "monitor" {
  name     = "monitor"
  password = "monitor"
  tags     = ["monitoring"]
}
