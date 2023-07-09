# Generate a publicly accessible EC2 instance for testing
resource "aws_instance" "ip2cr-test" {
  ami = "ami-053b0d53c279acc90"  # Ubuntu Server 22.04 LTS
  instance_type = "t2.micro"

  tags = {
    "Name": "ip2cr-test"
    "app": "ip2cr"
  }
}