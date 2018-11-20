# alarm/config to scale up when CPU util > 80
resource "aws_cloudwatch_metric_alarm" "ECSServiceScaleUpAlarm" {
  alarm_name            = "ECSServiceScaleUpAlarm"
  comparison_operator   = "GreaterThanOrEqualToThreshold"
  metric_name           = "CPUUtilization"
  namespace             = "AWS/ECS"
  period                = "60"
  evaluation_periods    = "1"
  statistic             = "Average"
  threshold             = "80"
  alarm_description     = "CPU Alarm to trigger ECS Service Auto-Scale Up"
  alarm_actions         = ["${aws_appautoscaling_policy.scale_up.arn}"]

  dimensions {
    ClusterName = "container-cluster"
    ServiceName = "nginx"
  }
}

resource "aws_appautoscaling_policy" "scale_up" {
  name                = "nginx-scale-up"
  resource_id         = "service/${aws_ecs_cluster.container-cluster.name}/${aws_ecs_service.nginx.name}"
  scalable_dimension  = "ecs:service:DesiredCount"
  service_namespace   = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 60

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = 1
    }
  }
  
  depends_on = ["aws_appautoscaling_target.nginx-up"]
}

resource "aws_appautoscaling_target" "nginx-up" {
  max_capacity       = 100
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.container-cluster.name}/${aws_ecs_service.nginx.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# alarm/config to scale down when CPU util < threshold
resource "aws_cloudwatch_metric_alarm" "ECSServiceScaleDownAlarm" {
  alarm_name            = "ECSServiceScaleDownAlarm"
  comparison_operator   = "LessThanOrEqualToThreshold"
  metric_name           = "CPUUtilization"
  namespace             = "AWS/ECS"
  period                = "60"
  evaluation_periods    = "1"
  statistic             = "Average"
  threshold             = "50"
  alarm_description     = "CPU Alarm to trigger ECS Service Auto-Scale Down"
  alarm_actions         = ["${aws_appautoscaling_policy.scale_down.arn}"]

  dimensions {
    ClusterName = "container-cluster"
    ServiceName = "nginx"
  }
}

resource "aws_appautoscaling_policy" "scale_down" {
  name                = "nginx-scale-down"
  resource_id         = "service/${aws_ecs_cluster.container-cluster.name}/${aws_ecs_service.nginx.name}"
  scalable_dimension  = "ecs:service:DesiredCount"
  service_namespace   = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 60

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.nginx-down"]
}

resource "aws_appautoscaling_target" "nginx-down" {
  max_capacity       = 100
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.container-cluster.name}/${aws_ecs_service.nginx.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
