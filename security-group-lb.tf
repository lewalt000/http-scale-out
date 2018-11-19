resource "aws_security_group" "load-balancer" {
  name    = "load-balancer"
  vpc_id  = "${aws_default_vpc.default.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress  {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["${aws_default_subnet.us-east-2a.cidr_block}",
                   "${aws_default_subnet.us-east-2b.cidr_block}",
                   "${aws_default_subnet.us-east-2c.cidr_block}"
                  ]
  }
}
