include {
    path = find_in_parent_folders()
}

inputs = {
    rmq_host          = "http://127.0.0.1:15672"
    rmq_instance_name = "rabbitmq1"
    team_username     = "teamA"
    team_password     = "teamA"
}

terraform {
    source = "${find_in_parent_folders("src")}///"
}