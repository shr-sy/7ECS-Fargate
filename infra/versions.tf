terraform {
  required_version = ">= 1.3.0"

  cloud {
    organization = "Exercises"
    workspaces {
      name = "ecs-fargate-7-services"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
