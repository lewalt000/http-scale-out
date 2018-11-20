resource "aws_ecs_service" "nginx" {
  name            = "nginx"
  cluster         = "${aws_ecs_cluster.container-cluster.id}"
  task_definition = "${aws_ecs_task_definition.nginx.arn}"
  desired_count   = 1  # only used for intitial deployment, afterwards auto-scaling determines desired count
  iam_role        = "${aws_iam_role.ecs-service-role.arn}"
  depends_on      = ["aws_iam_role.ecs-service-role"]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  # let auto-scaling determine desired count after initial deployment
  lifecycle {
    ignore_changes = ["desired_count"]
  }

  load_balancer {
    target_group_arn  = "${aws_lb_target_group.nginx.arn}"
    container_name    = "nginx"
    container_port    = 80
  }
}
