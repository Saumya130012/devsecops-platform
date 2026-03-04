module "vpc" {
  source               = "../../modules/vpc"
  project_name         = "devsecops"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  azs                  = ["us-east-1a", "us-east-1b"]
}

module "eks" {
  source             = "../../modules/eks"
  project_name       = "devsecops"
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = "t3.medium"
  desired_nodes      = 2
  min_nodes          = 1
  max_nodes          = 4
}
