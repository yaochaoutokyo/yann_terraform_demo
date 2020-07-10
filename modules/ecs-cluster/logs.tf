data "aws_caller_identity" "current" {}

# cw event rule
resource "aws_cloudwatch_event_rule" "ecs_event_stream" {
  count = var.environment == "dev" ? 0 : 1

  name        = "${local.name}-ecs-event-stream"
  description = "Passes ecs event logs for ${local.name} to a lambda that writes them to cw logs"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ecs"
  ],
  "detail": {
    "clusterArn": [
      "arn:aws:ecs:ap-northeast-1:${data.aws_caller_identity.current.account_id}:cluster/${local.name}"
    ],
    "lastStatus": [
      "STOPPED"
    ],
    "desiredStatus": [
      "STOPPED"
    ]
  }
}
PATTERN
}
resource "aws_cloudwatch_event_target" "sns" {
  count = var.environment == "dev" ? 0 : 1

  rule      = aws_cloudwatch_event_rule.ecs_event_stream[count.index].name
  target_id = "SendToSNS"
  arn       = data.terraform_remote_state.general.outputs.ecs_stopped_sns
}