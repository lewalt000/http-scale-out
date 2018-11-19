resource "aws_lb" "ecs-lb" {
  name                = "ecs-lb"
  security_groups     = ["${aws_security_group.load-balancer.id}"]
  internal            = false
  load_balancer_type  = "application"
  subnets             = [ "${aws_default_subnet.us-east-2a.id}",
                          "${aws_default_subnet.us-east-2b.id}",
                          "${aws_default_subnet.us-east-2c.id}"
                        ]

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "nginx" {
  name      = "nginx"
  port      = 80
  protocol  = "HTTP"
  vpc_id    = "${aws_default_vpc.default.id}"
}

resource "aws_lb_listener" "nginx" {
  load_balancer_arn = "${aws_lb.ecs-lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nginx.arn}"
    type             = "forward"
  }
}
