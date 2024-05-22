resource "aws_iam_role" "order_step_function_role" {
  name = "order_step_function_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "order_step_function_policy" {
  policy = <<END
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
                "lambda:*",
                "dynamodb:*",
                "sqs:*",
                "sns:*"
            ],
			"Resource": "*"
		}
	]
}
END
  role   = aws_iam_role.order_step_function_role.id
}

resource "aws_sns_topic" "order_publish" {
  name = "order-publish"
}

resource "aws_sqs_queue" "order_queue" {
  name                      = "order-queue"
  delay_seconds             = 5
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_queue_dlq.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "order_queue_dlq" {
  name                      = "order-queue-dlq"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_sfn_state_machine" "order_state_machine" {
  name     = "order-step-function"
  role_arn = aws_iam_role.order_step_function_role.arn

  definition = <<EOF
{
  "StartAt": "InsertOrder",
  "States": {
    "InsertOrder": {
      "Type": "Task",
      "Resource": "arn:aws:states:::dynamodb:putItem",
      "Parameters": {
        "TableName": "order",
        "Item": {
          "order_id": {
            "S.$": "$.order_id"
          }
        }
      },
      "ResultPath": null,
      "Next": "Process Order"
    },
    "Process Order": {
      "Type": "Task",
      "TimeoutSeconds": 60,
      "Resource": "arn:aws:states:::sqs:sendMessage.waitForTaskToken",
      "Parameters": {
        "QueueUrl": "${aws_sqs_queue.order_queue.url}",
        "MessageBody": {
          "MessageTitle.$": "$.order_id",
          "TaskToken.$": "$$.Task.Token"
        }
      },
      "ResultPath": "$.result",
      "Next": "SNS Publish",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "BackoffRate": 2,
          "MaxAttempts": 3,
          "IntervalSeconds": 5,
          "Comment": "retry",
          "JitterStrategy": "FULL"
        }
      ]
    },
    "SNS Publish": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message.$": "$",
        "TopicArn": "${aws_sns_topic.order_publish.arn}"
      },
      "End": true
    }
  }
}
EOF
}