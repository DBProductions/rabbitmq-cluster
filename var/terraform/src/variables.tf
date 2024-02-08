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

variable "federation_username" {
  type    = string
  default = "federation"
}

variable "federation_password" {
  type    = string
  default = "federation"
}

variable "msg-ttl-arguments" {
  default = <<EOF
{
  "x-queue-type": "quorum",
  "x-message-ttl": 5000
}
EOF
}

variable "stream-arguments" {
  default = <<EOF
{
  "x-queue-type": "stream"
}
EOF
}

variable "stream-arguments-short" {
  default = <<EOF
{
  "x-queue-type": "stream",
  "x-stream-max-segment-size-bytes": 250,
  "x-max-age": "5m"
}
EOF
}

variable "x-death-arguments" {
  default = <<EOF
{
  "x-match": "any-with-x",
  "x-first-death-reason": "rejected"  
}
EOF
}

variable "x-death-limit-arguments" {
  default = <<EOF
{
  "x-match": "any-with-x",
  "x-delivery-count": 2
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