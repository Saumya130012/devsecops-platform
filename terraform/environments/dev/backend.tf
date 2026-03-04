terraform {
  backend "s3" {
    bucket         = "devsecops-tfstate-terraform"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devsecops-tfstate-lock"
    encrypt        = true
  }
}
