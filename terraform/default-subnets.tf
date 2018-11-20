# config to get info about subnets in default vpc
resource "aws_default_subnet" "us-east-2a" {
  availability_zone = "us-east-2a"
}

resource "aws_default_subnet" "us-east-2b" {
  availability_zone = "us-east-2b"
}

resource "aws_default_subnet" "us-east-2c" {
  availability_zone = "us-east-2c"
}
