resource "aws_ecs_service" "nginx" {
  name            = "nginx"
  cluster         = "${aws_ecs_cluster.container-cluster.id}"
  task_definition = "${aws_ecs_task_definition.nginx.arn}"
  desired_count   = 1
  #iam_role        = "${aws_iam_role.ecs-service-role.arn}"
  depends_on      = ["aws_iam_role.ecs-service-role"]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}
