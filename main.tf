terraform {
  required_version = ">= 0.13.1"

  required_providers {
    shoreline = {
      source  = "shorelinesoftware/shoreline"
      version = ">= 1.11.0"
    }
  }
}

provider "shoreline" {
  retries = 2
  debug = true
}

module "ec2_instance_immediate_termination_after_attempting_to_launch" {
  source    = "./modules/ec2_instance_immediate_termination_after_attempting_to_launch"

  providers = {
    shoreline = shoreline
  }
}