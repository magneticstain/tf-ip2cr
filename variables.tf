variable "ami_id" {
    type = string
    description = "IDs of AMI to use for test EC2 instance"
    default = ""
    nullable = false
}

variable "accounts" {
    type = map(string)
    description = "Mapping of aliases->IAM roles of accounts to rollout plans to"
    default = {}
}