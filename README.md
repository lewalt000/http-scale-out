# http-scale-out

This project demonstrates how to deploy an auto-scaling http service in AWS using the Amazon Elastic Container Service (ECS), Terraform and Docker. It includes a sample http container built with nginx-uwsgi-python and Terraform configurations to automate provisioning of all required AWS resources.

The http service provided by this project is available at: http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api

## Prerequisites
To use this project you will need:
  * An AWS account with programmatic access for use by Terraform (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
  * AWS CLI installed (https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
  * Terraform installed (https://www.terraform.io/intro/getting-started/install.html)
  * Docker installed (https://docs.docker.com/install/)

## ECS Overview 
ECS can be used to deploy containers in AWS, load balance across container instances and auto-scale additional containers to support increased traffic load. The basic steps to use it are as follows:
  * Deploy ECS Cluster - this is a cluster of EC2 instances that runs docker containers according to available compute capacity
  * Create ECS Task - this defines details of a Docker container to run such as image name, port mapping and cpu/memory contraints
  * Create ECS Service - this maps to a task and defines how the container will run in the cluster, including number of instances, load balancing, and container placement strategy

To use ECS to run an auto-scaling http service, additional AWS resources are also required:
  * Elastic Load Balancer (ELB) - used to load balance requests to container instances running in the ECS cluster
  * Security Groups - needed to allow network traffic between ELB and container instances
  * IAM Roles - ECS cluster nodes must be attached to a certain role that allows interaction with the ECS API
  * AWS Launch Configuration - configures which AMI and IAM role is used by provisioned ECS cluster nodes
  * Auto-Scale Policies - auto-scale must be configured for both ECS cluster nodes AND the ECS service. See the 'Auto-Scale Settings' section for more info
  * Elastic Container Registry - a repository in AWS to store Docker images that are deployed as container on to the ECS cluster

## Automated ECS Provisioning with Terraform
Setting up the described ECS resources would be a lot of work manually, so it's recommended to automate using a configuration as code framework such as Terraform or Cloudformation. For this project, the open source Terraform tool is used (https://www.terraform.io/).

To use the included Terraform configurations, follow these steps in the ```terraform/``` directory:
  1. Make sure Terraform is installed (https://www.terraform.io/intro/getting-started/install.html)
  2. Define the AWS access and secret key for a user that has programmatic access in ```terraform/secrets.tfvars```:
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
  4. Inspect what Terraform would run before actually making changes: ```terraform plan -var-file="secrets.tfvars"```
  5. Provision the resources with Terraform: ```terraform apply -var-file="secrets.tfvars"```
  6. You should now have a fully provisioned system for deploying containers in ECS!

## HTTP Server Application
To test the ECS infrastructure setup, a sample HTTP Server Application is included along with scripts to build it as a docker container and deploy to ECS. It is a nginx-uwsgi-flask based HTTP server that serves a json response from the /api endpoint. The response is a json encoded dictionary of the form {index_number: random(ascii letter)}. The values are pseudo-randomly generated for each request using the ```random``` module (https://docs.python.org/2/library/random.html). The base docker image itself is adopted from this excellent docker hub project by ```tiangolo```: https://hub.docker.com/r/tiangolo/uwsgi-nginx-flask/

To build the server locally, follow these steps in the ```application/``` directory:
  1. Setup python virtualenv with: ```./scripts/dev_bootstrap.sh```
  2. Activate the virtualenv: ```source venv/bin/activate```
  3. Install pip requirements: ```pip install -r requirements.txt```
  4. Run server locally: ```python app/main.py```
  5. The server should now be running locally at http://localhost:8080

Changes to the application can be made in ```application/app/main.py```.

## Deploying New HTTP Server Versions

To deploy a new version of the HTTP server, first complete a few pre-requesite steps:
  1. Make sure the AWS CLI is installed (https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
  2. Configure the AWS CLI: `aws configure````aws configure```
  3. Authenticate Docker to push to AWS ECR: ```$(aws ecr get-login --no-include-email --region us-east-2)```
  ..* Note: on Ubunto 18.04 LTS, additional packages were needed for this to work: ```sudo apt install gnupg2 pass```
  4. Get the URI of the ECR Repository that was provisioned for your AWS account:
```
$ aws ecr describe-repositories --repository-names "http-api" --query 'repositories'[0].{Uri:repositoryUri}
{
    "Uri": "803293036930.dkr.ecr.us-east-2.amazonaws.com/http-api"
}
```
  5. Update the ```$ECR_URI``` variable in ```application/scripts/deploy.sh``` with the Uri for your account

With the pre-req's setup, a new build with the latest changes in ```app/main.py``` can be deployed via:
  * Run ```application/scripts/deploy.sh```

## Deployment Mechanism Notes
The deployment process works by building a new version of the docker image and pushing it to the AWS Elastic Container Registry. It then instructs ECS to force a retry of the current task definition. This causes ECS to download the latest version availabile in the ECR repo and deploy new instances to the cluster. It automatically follows a blue-green deployment strategy by following these steps:
  1. deploy new container instances
  2. check that new container instances are healthy
  3. route traffic to the new instances
  4. delete the old container instances

Note: this is just an example script to automate a test deployment, but is not suitable for production purposes. For production, a more robust deployment solution should be used. This would either be a more robust tool developed using the AWS SDK, or integrating with a cloud service like AWS CodePipeline.
  

## Auto-Scale Settings
Some notes on the auto-scale setup. First of all, it's important to note that TWO pieces of the infrastructure need to be configured for auto-scale:
  1. The number of http server docker containers being run on the ECS cluster. AWS refers to this as "Service Auto Scaling" (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html)
  2. The number of nodes in the ECS cluster. If too many containers are deployed in the cluster from use case 1), there won't be enough free capacity to deploy more.

In both cases, "Target Tracking Approach" is used to define the auto-scaling policy. With Target Tracking, a target CPU utilization is defined and AWS adjusts the number of containers or ECS instances to try and maintain this target. Target Tracking automatically creates and manages the required CloudWatch alarms to engage auto-scaling which makes it easy to setup with minimal configuration. The documentation about this approach can be found at:
  * For "Service Auto Scaling": https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-autoscaling-targettracking.html
  * For "EC2 Auto Scaling": https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html

For this test setup the following thresholds are used:
  * service auto scale target: 80%
  * ECS cluster node auto scale target: 30%

Note: the 30% target for the ECS Cluster scaling is definitely on the conservative side and could probably be increased after more testing. However, it's recommended to be somewhat conservative with this setting so enough ECS cluster capacity is always availble for deploying more container instances. This is especially because new container instances can be deployed much faster than additional ECS cluster nodes.

## Load Testing
To test the auto-scaling feature, a load testing tool can be used to generate requests to the HTTP server. https://github.com/denji/awesome-http-benchmark has a great overview of the many tools available. For a quick test, the open source ```hey``` utility is a great option: https://github.com/rakyll/hey/blob/master/README.md.

After installing with ```go get -u github.com/rakyll/hey```, load can be generated to the HTTP API like this:
```
~/go/bin/hey -q 5 -z 10m http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
~/go/bin/hey -q 10 -z 10m http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
~/go/bin/hey -q 15 -z 10m http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
~/go/bin/hey -q 20 -z 10m http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
```

The result of this test showed that both new containers and ECS nodes were added as needed to maintain stable CPU utilization across the cluster.

These graphs shows CPU and memory utilization in the top graph and HTTP Request Count in the bottom graph. The inflection points in the graph are when new instances are brought online, thus lowering the CPU utilization:
![perf_graph](https://i.imgur.com/4Jpvr2n.png)


Accordingly, the ECS event log shows new container instances added in response to the increased load:
![event_log](https://i.imgur.com/CJ9q4Pg.png)


After the load test was completed, the ECS event log shows container instances being removed in repsonse to the decreased load:
![event_log](https://i.imgur.com/Bo8Cs8i.png)

## API Demonstration
For good measure, here is an example response of an API request. Note, the key values are randomly generated and will be different for each request.
```
$ curl http://ecs-lb-2036911475.us-east-2.elb.amazonaws.com/api
{"0":"e","1":"d","2":"f","3":"W","4":"s","5":"V","6":"H","7":"C","8":"o","9":"J","10":"y","11":"Y","12":"r","13":"s","14":"S","15":"b","16":"q","17":"M","18":"K","19":"a","20":"I","21":"p","22":"l","23":"B","24":"L","25":"Z","26":"F","27":"L","28":"y","29":"c","30":"x","31":"m","32":"F","33":"l","34":"E","35":"u","36":"M","37":"Z","38":"O","39":"y","40":"w","41":"H","42":"l","43":"X","44":"f","45":"h","46":"B","47":"E","48":"m","49":"Y","50":"k","51":"r"}
```

## Future Work
Here are areas where the project could be further refined:

* Use a full featured deployment system and build pipeline. For easy integration with ECS, Amazon CodePipeline would be a good place to start (https://aws.amazon.com/codepipeline/)
* Modularize Terraform config's (https://www.terraform.io/docs/modules/index.html)
* Re-factor tunable Terraform settings out into variables (https://www.terraform.io/intro/getting-started/variables.html)
