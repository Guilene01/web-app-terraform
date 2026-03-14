output "load_balancer_url" {
  value = aws_lb.web_alb.dns_name
}

output "instance_ids" {
  value = aws_instance.web[*].id
}