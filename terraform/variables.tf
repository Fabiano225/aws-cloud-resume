variable "region" {
    type = string
    default = "us-east-1"
}

variable "bucket_name" {
    type = string
    default = "terraform_resume_bucket"
}

variable "lambda_function_name" {
    type = string
    default = "terraform_resume_lambda"
}

variable "visitor_count_table_name" {
    type = string
    default = "terraform_visitor_count_table"
}

variable "ip_address_table_name" {
    type = string
    default = "terraform_ip_address_table"
}

variable "waf_acl_arn" {
  type        = string
  description = "ARN of the WAF ACL to associate with the CloudFront distribution"
}