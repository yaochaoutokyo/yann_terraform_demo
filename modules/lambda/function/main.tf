resource aws_lambda_function lambda {
  function_name                  = format("%s", var.function_name)
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  description                    = var.description
  role                           = var.role_arn
  handler                        = var.handler
  runtime                        = var.runtime
  publish                        = var.publish
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.concurrency
  timeout                        = var.lambda_timeout
  tags                           = var.tags

  dynamic "vpc_config" {
    for_each = length(var.vpc_config) < 1 ? [] : [var.vpc_config]
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  dynamic "environment" {
    for_each = length(var.environment) < 1 ? [] : [var.environment]
    content {
      variables = environment.value.variables
    }
  }

  lifecycle {
    ignore_changes = [
      filename,
    ]
  }

  depends_on = [aws_cloudwatch_log_group.log_group]
}

resource aws_lambda_function_event_invoke_config latest {
  function_name                = aws_lambda_function.lambda.function_name
  qualifier                    = "$LATEST"
  maximum_event_age_in_seconds = var.event_age_in_seconds
  maximum_retry_attempts       = var.retry_attempts
}

# Cloud watch
resource aws_cloudwatch_log_group log_group {
  name              = format("/aws/lambda/%s", var.function_name)
  retention_in_days = var.log_retention

  tags = var.tags
}