data "aws_caller_identity" "current" {}

resource "aws_dynamodb_table" "terraform_visitor_count_table" {
  name           = var.visitor_count_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "MetricName"

  attribute {
    name = "MetricName"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "initialVisitorCount" {
  table_name = aws_dynamodb_table.terraform_visitor_count_table.name
  hash_key = aws_dynamodb_table.terraform_visitor_count_table.hash_key

  item = jsonencode({
    "MetricName" = {"S": "visitor_count"},
    "VisitorCount" = {"N": "0"}
  })
}

resource "aws_dynamodb_table" "terraform_ip_address_table" {
  name           = var.ip_address_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "IP"

  attribute {
    name = "IP"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToLive"
    enabled = true
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.lambda_function_name}_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query"
    ]
    resources = [
      aws_dynamodb_table.terraform_visitor_count_table.arn,
      aws_dynamodb_table.terraform_ip_address_table.arn
    ]
  }
  statement {
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_policy_res" {
  name = "${var.lambda_function_name}_policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy_res.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "terraform_resume_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
        VISITOR_TABLE = aws_dynamodb_table.terraform_visitor_count_table.name
        IP_TABLE = aws_dynamodb_table.terraform_ip_address_table.name
    }
  }
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_resume_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.terraform_visitor_counter_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_api" "terraform_visitor_counter_api" {
    name          = "VisitorCounterAPI"
    protocol_type = "HTTP"

    cors_configuration {
      allow_origins = ["*"]
      allow_methods = ["POST", "OPTIONS", "GET"]
      allow_headers = ["content-type"]
      max_age = 300
    }
}

resource "aws_apigatewayv2_route" "terraform_visitor_counter_route" {
  api_id    = aws_apigatewayv2_api.terraform_visitor_counter_api.id
  route_key = "$default"
  target = "integrations/${aws_apigatewayv2_integration.terraform_visitor_counter_integration.id}"
}

resource "aws_apigatewayv2_integration" "terraform_visitor_counter_integration" {
  api_id           = aws_apigatewayv2_api.terraform_visitor_counter_api.id
  integration_type = "AWS_PROXY"

  payload_format_version = "2.0"
  integration_uri    = aws_lambda_function.terraform_resume_lambda.invoke_arn
}

resource "aws_apigatewayv2_stage" "terraform_visitor_counter_stage" {
  api_id      = aws_apigatewayv2_api.terraform_visitor_counter_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "terraform-resume-frontend-bucket"
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  web_acl_id = var.waf_acl_arn
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  

  aliases = ["fabiano-petillo.dev"]

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source = "${path.module}/../frontend/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "style.css"
  source       = "${path.module}/../frontend/style.css"
  content_type = "text/css"
}

resource "aws_s3_object" "js" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "script.js"
  source       = "${path.module}/../frontend/script.js"
  content_type = "application/javascript"
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = "fabiano-petillo.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}