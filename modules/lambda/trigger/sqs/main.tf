resource "aws_sqs_queue" "queue" {
  name                       = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout
  tags                       = var.tags
}

resource "aws_lambda_event_source_mapping" "trigger" {
  batch_size       = var.batch_size
  enabled          = var.event_source_mapping_enabled
  event_source_arn = aws_sqs_queue.queue.arn
  function_name    = var.function_name
}
