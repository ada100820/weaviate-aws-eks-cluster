variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "weaviate-eks"
}

variable "vpc_id" {
  type = string
  # e.g., "vpc-12345678"
}

variable "private_subnets" {
  type = list(string)
  # e.g., ["subnet-aaaaaaa","subnet-bbbbbbb"]
}

variable "public_subnets" {
  type = list(string)
  # e.g., ["subnet-ccccccc","subnet-ddddddd"]
}

variable "desired_capacity" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}
