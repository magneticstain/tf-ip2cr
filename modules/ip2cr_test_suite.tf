# Generate all resources supported by ip2cr

# At a high level, we want to create an EC2 instance, put a NLB and ALB in front of it, and then attach a newly-created cloudfront distro to the ALB

# publicly accessible EC2 instance
resource "aws_instance" "ip2cr-test" {
  ami = "ami-053b0d53c279acc90"  # Ubuntu Server 22.04 LTS
  instance_type = "t2.micro"
  key_name = "default"  # update as needed

  tags = {
    "Name": "ip2cr-test"
    "app": "ip2cr"
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

# alb
resource "aws_lb" "ip2cr-testing-alb" {
  name               = "IP2CR-Testing-ALB"
  load_balancer_type = "application"
  subnets            = ["subnet-06a2ae760a3f27e40", "subnet-01e351716cd2b9f49"]  # Update Me
  security_groups    = [aws_security_group.ip2cr-test-sg.id]
}

resource "aws_lb_target_group" "ip2cr-testing-tg" {
  name        = "IP2CR-Testing-TgtGrp"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-07e884ddac0458356"  # Update Me
  target_type = "instance"
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

  enabled             = true

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
    app = "ip2cr"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}