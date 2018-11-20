data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name    = "name"
    values  = ["*amzn2-ami-ecs-hvm*"]
  }
}

resource "aws_launch_configuration" "ecs-launch-config" {
  name                  = "ecs_launch_config"
  image_id              = "${data.aws_ami.ecs.id}"
  instance_type         = "t2.micro"
  iam_instance_profile  = "${aws_iam_instance_profile.ecs-instance-profile.id}"
  security_groups       = ["${aws_security_group.ecs-instance.id}"]
  key_name              = "linux-ssh-key"

  # needed for autoscale created ec2 instance to join ecs cluster
  user_data             = <<EOF
#!/bin/bash
echo ECS_CLUSTER=container-cluster >> /etc/ecs/ecs.config
                          EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs-autoscale" {
  name                  = "ecs_autoscale_group"
  launch_configuration  = "${aws_launch_configuration.ecs-launch-config.name}"
  availability_zones    = ["us-east-2a", "us-east-2b", "us-east-2c"]
  min_size              = 3
  max_size              = 20

  lifecycle {
    create_before_destroy = true
  }
}
