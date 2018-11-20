# Create a Container Registry Repository to store the http-api docker image
resource "aws_ecr_repository" "http-api" {
  name = "http-api"
}
