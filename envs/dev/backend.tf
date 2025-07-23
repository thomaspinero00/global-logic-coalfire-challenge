terraform {
  backend "s3" {
    bucket         = "global-logic-challenge-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "global-logic-challenge-tf-lock"
    encrypt        = true
  }
}
