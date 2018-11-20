#!/bin/sh
ECR_URI='803293036930.dkr.ecr.us-east-2.amazonaws.com/http-api:latest'

docker build -t http-api .
docker tag http-api:latest $ECR_URI
docker push $ECR_URI
aws ecs update-service --cluster container-cluster --service nginx --force-new-deployment
