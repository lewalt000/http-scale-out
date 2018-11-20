# config to get info about default vpc
resource "aws_default_vpc" "default" {
  tags {
    Name = "Default VPC"
  }
}
