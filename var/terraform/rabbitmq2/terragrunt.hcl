include {
    path = find_in_parent_folders()
}

inputs = {
    rmq_host          = "http://127.0.0.1:15673"
    rmq_instance_name = "rabbitmq2"
    team_username     = "teamB"
    team_password     = "teamB"
}

terraform {
    source = "../src"
}