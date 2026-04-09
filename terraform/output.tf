output "api_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_stage.terraform_visitor_counter_stage.invoke_url
}