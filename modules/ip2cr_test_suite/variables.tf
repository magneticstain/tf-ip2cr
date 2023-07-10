variable "subnets" {
    type = list
    description = "IDs of subnets that load balancers should live in"
}

variable "vpc" {
    type = string
    description = "VPC that load balancers should live in"
}