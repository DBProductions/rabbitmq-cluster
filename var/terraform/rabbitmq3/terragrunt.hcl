include {
    path = find_in_parent_folders()
}

inputs = {
    rmq_host          = "http://127.0.0.1:15674"
    rmq_instance_name = "rabbitmq3"
    team_username     = "teamC"
    team_password     = "teamC"
}

terraform {
    source = "${find_in_parent_folders("src")}///"
}