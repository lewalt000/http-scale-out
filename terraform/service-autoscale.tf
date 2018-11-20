resource "aws_appautoscaling_policy" "service_autoscale" {
  name                = "nginx-autoscale"
  policy_type         = "TargetTrackingScaling"
  resource_id         = "service/${aws_ecs_cluster.container-cluster.name}/${aws_ecs_service.nginx.name}"
  scalable_dimension  = "ecs:service:DesiredCount"
  service_namespace   = "ecs"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80.0
  }
  
  depends_on = ["aws_appautoscaling_target.nginx-autoscale"]
}

resource "aws_appautoscaling_target" "nginx-autoscale" {
  max_capacity       = 20
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.container-cluster.name}/${aws_ecs_service.nginx.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
