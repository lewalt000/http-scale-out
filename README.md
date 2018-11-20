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
To test the ECS infrastructure setup, a sample HTTP Server Application is included along with scripts to build it as a docker container and deploy to ECS. It is a nginx-uwsgi-flask based HTTP server that serves a json response from the /api endpoint. The response is a json encoded dictionary of the form {index_number: random(ascii letter)}. The values are pseudo-randomly generated for each request using the ```random``` module (https://docs.python.org/2/library/random.html). The base docker image itself is adopted from this excellent docker hub project by ```tiangolo```: https://hub.docker.com/r/tiangolo/uwsgi-nginx-flask/

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

## Auto-Scale Settings
Some notes on the auto-scale setup. First of all, it's important to note that TWO pieces of the infrastructure need to be configured for auto-scale:
  1. The number of http server docker containers being run on the ECS cluster. AWS refers to this as "Service Auto Scaling" (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html)
  2. The number of nodes in the ECS cluster. If too many containers are deployed in the cluster from use case 1), there won't be enough free capacity to deploy more. This is done with the same type of Auto-Scale groups used for EC2 instances, using a launch template that configures new EC2 instances to join the ECS cluster automatically. (https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)

In both cases, "Target Tracking Approach" is used to define the auto-scaling policy. With Target Tracking, a target CPU utilization is defined and AWS adds or remove instances or containers to try and maintain this target. Target Tracking automatically creates and manages the required CloudWatch alarms to engage the auto-scaling which makes it easy to setup with minimal configuration. The documentation about this approach is at:
  * For "Service Auto Scaling": https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-autoscaling-targettracking.html
  * For "EC2 Auto Scaling": https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html

For this test setup the following thresholds are used:
  * service auto scale target: 80%
  * ECS cluster node auto scale target: 30%

## Load Testing
To test the auto-scaling feature, a load testing tool can be used to generate requests to the HTTP server. https://github.com/denji/awesome-http-benchmark has a great overview of the many tools available. For a quick test, the open source ```hey`` utility is a great option: https://github.com/rakyll/hey/blob/master/README.md.

After installing with ```go get -u github.com/rakyll/hey```, some load with increasing traffic can be generated to the server API endpoint with:
```
~/go/bin/hey -q 5 -z 10m http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
~/go/bin/hey -q 10 -z 10m http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
~/go/bin/hey -q 15 -z 10m http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
~/go/bin/hey -q 20 -z 10m http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
```

The result of this test showed that both new containers and ECS nodes were added as neeed to maintain a stable CPU utilization across the cluster.

This graph shows CPU and memory utilization at the top and Request Count at the bottom. The inflection points in the graph where CPU load decreases are when new instances are brought online:
(https://i.imgur.com/4Jpvr2n.png)

Accordingly the ECS logs show the new container instances being brought up in response to the increased load:
(https://i.imgur.com/CJ9q4Pg.png)

## Future Work
Here are areas where the project could be further refined:

* Use a full featured deployment system and build pipeline. For easy integration with ECS, Amazon Code would be a good place to start (https://aws.amazon.com/codepipeline/)
* Modularize Terraform config's (https://www.terraform.io/docs/modules/index.html)
* Re-factor tunable Terraform settings out into variables (https://www.terraform.io/intro/getting-started/variables.html)
