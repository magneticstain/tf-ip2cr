variable "ami_id" {
    type = string
    description = "IDs of AMI to use for test EC2 instance"
    default = ""
    nullable = false
}

variable "key_pair_name" {
    type = string
    description = "Name of SSH key pair to use for access to test EC2 instance"
    default = ""
    nullable = false
}

variable "subnets" {
    type = list
    description = "IDs of subnets that load balancers should live in"
    default = []
    nullable = false
}

variable "vpc" {
    type = string
    description = "VPC that load balancers should live in"
    default = ""
    nullable = false
}