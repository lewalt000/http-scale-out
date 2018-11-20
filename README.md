# http-scale-out

This project demonstrates how to deploy an auto-scaling http service in AWS using Amazon Elastic Container Service (ECS), Terraform and Docker. It includes a sample http container built with nginx-uwsgi-python and Terraform configurations to provision all required AWS resources.

The http service provided this project can be inspected at: http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api

## Prerequisites
To use this project you will need:
  * An AWS account with programmatic access for use by Terraform
  * Terraform installed (https://www.terraform.io/intro/getting-started/install.html)
  * Docker installed (https://docs.docker.com/install/)

## ECS Overview 
ECS can be used to deploy containers in AWS, load balance across container instances and auto-scale additional containers to support increased traffic to an application. The basic steps to use it are as follows:
  * Deploy ECS Cluster - this is a cluster of EC2 instances that can run Docker containers
  * Create ECS Task - this defines details of a Docker container to run, e.g. image name, port mapping and cpu/memory contraints
  * Create ECS Service - this maps to a task and defines how the container will run in the cluster, including number of instances, load balancing, and container placement strategy

To use ECS to run an auto-scaling http service, additional AWS resources are also required:
  * Elastic Load Balancer (ELB) - used to load balance requests to container instances running in the ECS cluster
  * Security Groups - needed to allow network traffic between ELB and container instances
  * IAM Roles - ECS cluster nodes must be attached to a certain role that allows interaction with the ECS API
  * AWS Launch Configuration - configures which AMI and IAM role is used by ECS cluster nodes 
  * Auto-Scale Policies - auto-scale must be configured for both ECS cluster nodes AND the ECS service. See the 'auto-scale' section for more info
  * Elastic Container Registry - a repository in AWS to store the Docker images deployed to ECS

## Automated ECS Provisioning with Terraform
Setting up the described ECS resources would be a lot of work manually, so thankfully it can be automated using the open source Terraform tool (https://www.terraform.io/).

To use the included Terraform configurations, follow these steps in the ```terraform/``` directory:
  1. Install Terraform (https://www.terraform.io/intro/getting-started/install.html)
  2. Define an AWS access and secret key to use in ```terraform/secrets.tfvars```:
```
$ cat terraform/secrets.tfvars 
access_key = "foooooooo"
secret_key = "baaaaaaar"
```
  3. Initialize Terraform
```
$ terraform init -var-file="secrets.tfvars"
$ Terraform has been successfully initialized!
```
  4. Inspect what Terraform would run, before actually making changes: ```terraform plan -var-file="secrets.tfvars"```
  5. Provision the resources with Terraform: ```terraform apply -var-file="secrets.tfvars"```
  6. You should now have a fully provisioned system for deploying containers in ECS!

## HTTP Server Application
To test the ECS infrastructure setup, a sample HTTP Server Application is included, along with scripts to build it as a docker container and deploy to ECS. It is a nginx-uwsgi-flask based HTTP server that serves a json response from the /api endpoint. The response is a json encoded dictionary of the form {index_number: random(ascii letter)}. The values are pseudo-randomly generated for each request using the ```random``` module (https://docs.python.org/2/library/random.html). The base docker image itself is adopted from this excellent docker hub project by ```tiangolo```: https://hub.docker.com/r/tiangolo/uwsgi-nginx-flask/

To build the server locally, follow these steps in the ```application/``` directory:
  1. Setup python virtualenv with:
```
$ ./scripts/dev_bootstrap.sh
#################
To run server locally for development:
source venv/bin/activate
python app/main.py
```
  2. Activate the virtualenv: ```source venv/bin/activate```
  3. Install pip requirements: ```pip install -r requirements.txt```
  4. Run server locally: ```python app/main.py```
  5. The server should now be running locally at http://localhost:8080

Changes to the application can be made in ```app/main.py```.


## Future Work
Here are areas where the project could be further refined:

* Use a full featured deployment system and build pipeline. For easy integration with ECS, Amazon Code would be a good place to start (https://aws.amazon.com/codepipeline/)
* Modularize Terraform config's (https://www.terraform.io/docs/modules/index.html)
* Re-factor tunable Terraform settings out into variables (https://www.terraform.io/intro/getting-started/variables.html)
