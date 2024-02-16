# Generate all resources supported by ip2cr

# At a high level, we want to create an EC2 instance, put a NLB and ALB in front of it, and then attach a newly-created cloudfront distro to the ALB

# networking
variable "vpc_cidr" {
  default = "192.168.200.0/26"
}

resource "aws_vpc" "ip2cr-net" {
  cidr_block                        = var.vpc_cidr
  assign_generated_ipv6_cidr_block  = true
  
  tags = {
    Name = "ip2cr-net"
  }
}

variable "num_subnets" {
  default = 3
}

locals {
    ipv4_subnets = cidrsubnets(aws_vpc.ip2cr-net.cidr_block, [for i in range(var.num_subnets) : "2"]...)
    # we can't use cidrsubnets() for IPv6 since it doesn't support increasing the mask
}

resource "aws_subnet" "ip2cr-subnet-1" {
  vpc_id                    = aws_vpc.ip2cr-net.id
  cidr_block                = local.ipv4_subnets[0]
  ipv6_cidr_block           = cidrsubnet(aws_vpc.ip2cr-net.ipv6_cidr_block, 8, 2)
  map_public_ip_on_launch   = true
  availability_zone         = "us-east-1a"

  tags = {
    Name = "ip2cr-subnet-1"
  }
}

resource "aws_subnet" "ip2cr-subnet-2" {
  vpc_id                    = aws_vpc.ip2cr-net.id
  cidr_block                = local.ipv4_subnets[1]
  ipv6_cidr_block           = cidrsubnet(aws_vpc.ip2cr-net.ipv6_cidr_block, 8, 4)
  map_public_ip_on_launch   = true
  availability_zone         = "us-east-1b"

  tags = {
    Name = "ip2cr-subnet-2"
  }
}

resource "aws_subnet" "ip2cr-subnet-3" {
  vpc_id                    = aws_vpc.ip2cr-net.id
  cidr_block                = local.ipv4_subnets[2]
  ipv6_cidr_block           = cidrsubnet(aws_vpc.ip2cr-net.ipv6_cidr_block, 8, 8)
  map_public_ip_on_launch   = true
  availability_zone         = "us-east-1c"

  tags = {
    Name = "ip2cr-subnet-3"
  }
}

resource "aws_internet_gateway" "ip2cr-igw" {
  vpc_id = aws_vpc.ip2cr-net.id

  tags = {
    Name = "ip2cr-igw"
  }
}

# ec2
resource "aws_instance" "ip2cr-test" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ip2cr-subnet-1.id

  tags = {
    Name: "ip2cr-testing"
    app: "ip2cr-testing"
  }

  depends_on = [ aws_internet_gateway.ip2cr-igw ]
}

resource "aws_security_group" "ip2cr-test-sg" {
  name        = "IP2CR-Testing"
  description = "Allow access to EC2 instance for IP2CR testing purposes"
  vpc_id      = aws_vpc.ip2cr-net.id

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
    aws_instance.ip2cr-test.public_ip
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
  value = [
    aws_cloudfront_distribution.ip2cr-cf-distro.arn,
    aws_cloudfront_distribution.ip2cr-cf-distro.domain_name
  ]
}

# elbs
## alb
resource "aws_lb" "ip2cr-testing-alb" {
  name               = "IP2CR-Testing-ALB"
  load_balancer_type = "application"
  ip_address_type    = "dualstack"
  subnets            = [aws_subnet.ip2cr-subnet-1.id, aws_subnet.ip2cr-subnet-2.id, aws_subnet.ip2cr-subnet-3.id]
  security_groups    = [aws_security_group.ip2cr-test-sg.id]

  tags = {
    app: "ip2cr-testing"
  }
}

resource "aws_lb_target_group" "ip2cr-testing-tg" {
  name        = "IP2CR-Testing-TgtGrp"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ip2cr-net.id
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
  value = [
    aws_lb.ip2cr-testing-alb.arn,
    aws_lb.ip2cr-testing-alb.dns_name
  ]
}

## nlb
resource "aws_lb" "ip2cr-testing-nlb" {
  name               = "IP2CR-Testing-NLB"
  internal           = false
  load_balancer_type = "network"
  ip_address_type    = "dualstack"
  subnets            = [aws_subnet.ip2cr-subnet-1.id, aws_subnet.ip2cr-subnet-2.id, aws_subnet.ip2cr-subnet-3.id]

  enable_cross_zone_load_balancing = false

  tags = {
    app: "ip2cr-testing"
  }
}

resource "aws_lb_target_group" "ip2cr-testing-nlb-tg" {
  name        = "IP2CR-Testing-NLB-TgtGrp"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.ip2cr-net.id
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
  value = [
    aws_lb.ip2cr-testing-nlb.arn,
    aws_lb.ip2cr-testing-nlb.dns_name
  ]
}

## classic (aka ELBv1)
resource "aws_elb" "ip2cr-testing-elb" {
  name                      = "IP2CR-Testing-ELB"
  subnets                   = [aws_subnet.ip2cr-subnet-1.id, aws_subnet.ip2cr-subnet-2.id, aws_subnet.ip2cr-subnet-3.id]
  instances                 = [aws_instance.ip2cr-test.id]
  cross_zone_load_balancing = false
  
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = {
    app: "ip2cr-testing"
  }
}

output "ip2cr-testing-elb-metadata" {
  value = [
    aws_elb.ip2cr-testing-elb.arn,
    aws_elb.ip2cr-testing-elb.dns_name
  ]
}
