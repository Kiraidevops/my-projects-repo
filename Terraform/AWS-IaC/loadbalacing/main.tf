# ---- loadbalancing.main --- 

resource "aws_lb" "kirai_lb" {
  name = "kirai-loadbalancer"
  security_groups = var.public_sg
  subnets = var.public_subnets
  idle_timeout = 400
}

resource "aws_lb_target_group" "kirai_tg" {
  name = "kirai-lb-tg-${substr(uuid(), 0, 3)}" #generate name 
  port = var.tg_port
  protocol = var.tg_protocol
  vpc_id = var.tg_vpc_id
  lifecycle {
    ignore_changes = [ name ]
    create_before_destroy = true #for listener arn problem,
  }
  health_check {
    healthy_threshold = var.lb_healthy_threshold
    unhealthy_threshold = var.lb_unhealthy_threshold
    timeout = var.lb_timeout
    interval = var.lb_interval
   }
}
  
resource "aws_lb_listener" "kirai_lb_listener" {
  load_balancer_arn = aws_lb.kirai_lb.arn #arn found in tf.state in state
  port = var.listener_port
  protocol = var.listener_protocol
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.kirai_tg.arn
  }
}