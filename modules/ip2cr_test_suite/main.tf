# Generate all resources supported by ip2cr

# At a high level, we want to create an EC2 instance, put a NLB and ALB in front of it, and then attach a newly-created cloudfront distro to the ALB

# ec2
resource "aws_instance" "ip2cr-test" {
  ami                 = var.ami_id
  instance_type       = "t2.micro"
  ipv6_address_count  = 1

  tags = {
    Name: "ip2cr-testing"
    app: "ip2cr-testing"
  }
}

resource "aws_security_group" "ip2cr-test-sg" {
  name        = "IP2CR-Testing"
  description = "Allow access to EC2 instance for IP2CR testing purposes"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ip2cr-ec2-metadata" {
  value = [
    aws_instance.ip2cr-test.arn,
    aws_instance.ip2cr-test.public_ip,
    aws_instance.ip2cr-test.ipv6_addresses
  ]
}

# cloudfront
resource "aws_cloudfront_distribution" "ip2cr-cf-distro" {
  origin {
    domain_name = aws_lb.ip2cr-testing-alb.dns_name
    origin_id   = "ip2cr-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "ip2cr-alb-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    app: "ip2cr-testing"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "ip2cr-cf-distro-metadata" {
  value = [aws_cloudfront_distribution.ip2cr-cf-distro.arn, aws_cloudfront_distribution.ip2cr-cf-distro.domain_name]
}

# elbs
## alb
resource "aws_lb" "ip2cr-testing-alb" {
  name               = "IP2CR-Testing-ALB"
  load_balancer_type = "application"
  ip_address_type    = "dualstack"
  subnets            = var.subnets
  security_groups    = [aws_security_group.ip2cr-test-sg.id]

  tags = {
    app: "ip2cr-testing"
  }
}

resource "aws_lb_target_group" "ip2cr-testing-tg" {
  name        = "IP2CR-Testing-TgtGrp"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc
  target_type = "instance"

  tags = {
    app: "ip2cr-testing"
  }
}

resource "aws_lb_target_group_attachment" "ip2cr-testing-tg-attachment" {
  target_group_arn = aws_lb_target_group.ip2cr-testing-tg.arn
  target_id        = aws_instance.ip2cr-test.id
  port             = 80
}

resource "aws_lb_listener" "ip2cr-testing-alb-listener" {
  load_balancer_arn = aws_lb.ip2cr-testing-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ip2cr-testing-tg.arn
  }

  tags = {
    app: "ip2cr-testing"
  }
}

output "ip2cr-testing-alb-metadata" {
  value = [aws_lb.ip2cr-testing-alb.arn, aws_lb.ip2cr-testing-alb.dns_name]
}

## nlb
resource "aws_lb" "ip2cr-testing-nlb" {
  name               = "IP2CR-Testing-NLB"
  internal           = false
  load_balancer_type = "network"
  ip_address_type    = "dualstack"
  subnets            = var.subnets

  enable_cross_zone_load_balancing = false

  tags = {
    app: "ip2cr-testing"
  }
}

resource "aws_lb_target_group" "ip2cr-testing-nlb-tg" {
  name        = "IP2CR-Testing-NLB-TgtGrp"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc
  target_type = "instance"

  tags = {
    app: "ip2cr-testing"
  }
}

resource "aws_lb_target_group_attachment" "ip2cr-testing-nlb-tg-attachment" {
  target_group_arn = aws_lb_target_group.ip2cr-testing-nlb-tg.arn
  target_id        = aws_instance.ip2cr-test.id
  port             = 80
}

resource "aws_lb_listener" "ip2cr-testing-nlb-listener" {
  load_balancer_arn = aws_lb.ip2cr-testing-nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ip2cr-testing-nlb-tg.arn
  }

  tags = {
    app: "ip2cr-testing"
  }
}

output "ip2cr-testing-nlb-metadata" {
  value = [aws_lb.ip2cr-testing-nlb.arn, aws_lb.ip2cr-testing-nlb.dns_name]
}

## classic (aka ELBv1)
resource "aws_elb" "ip2cr-testing-elb" {
  name                      = "IP2CR-Testing-ELB"
  availability_zones        = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances                 = [aws_instance.ip2cr-test.id]
  cross_zone_load_balancing = false

  tags = {
    app: "ip2cr-testing"
  }
}

output "ip2cr-testing-elb-metadata" {
  value = [aws_elb.ip2cr-testing-elb.arn, aws_elb.ip2cr-testing-elb.dns_name]
}
