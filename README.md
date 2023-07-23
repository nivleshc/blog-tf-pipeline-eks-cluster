# Provision an Amazon Elastic Kubernetes Service Cluster using Terraform Pipeline

This repository contains code to provision an Amazon Elastic Kubernetes Service cluster using a Serverless Pipeline for provisioning Terraform Projects, as described in https://nivleshc.wordpress.com/2023/03/28/use-aws-codepipeline-aws-codecommit-aws-codebuild-amazon-simple-storage-service-amazon-dynamodb-and-docker-to-create-a-pipeline-to-deploy-terraform-code/.

## Prerequisites
To deploy the Amazon Elastic Kubernetes Service (EKS) cluster, first create the serverless pipeline, as mentioned in the above link.

## What will be created
The following resources will be created using the code in this repository
- Amazon Virtual Private Cloud (VPC)
- 2 Public Subnets
- 2 Private Subnets
- 1 Internet Gateway
- 1 NAT Gateway
- 1 route table (public)
- 1 Amazon EKS cluster with a node group
- Prometheus microservice deployment inside the Amazon EKS cluster
- Grafana microservice deployment inside the Amazon EKS cluster
- Grafana dashboard deployment to display Amazon EKS cluster monitoring statistics

## High Level Architecture
Below is the high level architecture diagram for the solution. The resources in the pink rectangle will be created using the code in this repository.

The resources inside the orange rectangle belong to the serverless pipeline, which will be used to deploy this solution.

![High Level Architecture Diagram](/images/Serverless%20Pipeline%20-%20Amazon%20EKS%20Cluster.png "High Level Architecture Diagram")
## Implementation
Follow the instructions at https://nivleshc.wordpress.com/2023/06/12/create-an-amazon-elastic-kubernetes-service-cluster-using-a-serverless-terraform-pipeline/