variable "rmq_host" {}

variable "rmq_instance_name" {}

variable "rmq_username" {
  type    = string
  default = "rabbit"
}

variable "rmq_password" {
  type    = string
  default = "rabbit"
}

variable "team_username" {
  type    = string
  default = "team"
}

variable "team_password" {
  type    = string
  default = "team"
}

variable "stream-arguments" {
  default = <<EOF
{
  "x-queue-type": "stream"
}
EOF
}

variable "binding-arguments" {
  type = map

  default = {
    x-match = "all"
    country = "1"
  }
}

variable "binding-arguments-1" {
  type = map

  default = {
    x-match = "any"
    country = "1"
    rid     = "1"
  }
}

variable "binding-arguments-2" {
  type = map

  default = {
    x-match = "any"
    country = "2"
    rid     = "2"
  }
}

variable "binding-arguments-all" {
  type = map

  default = {
    x-match = "any"
    root    = "1"
  }
}