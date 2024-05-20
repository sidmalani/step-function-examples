resource "aws_iam_role" "simple_step_function_role" {
  name = "simple_step_function_role"

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

resource "aws_iam_role_policy" "simple_step_function_policy" {
  policy = <<END
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": "lambda:*",
			"Resource": "*"
		}
	]
}
END
  role   = aws_iam_role.simple_step_function_role.id
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "simple-step-function"
  role_arn = aws_iam_role.simple_step_function_role.arn

  definition = <<EOF
{
  "Comment": "A Hello World example of the Amazon States Language using an AWS Lambda Function",
  "StartAt": "Step1",
  "States": {
    "Step1": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.simple_step_function_lambda_1.arn}",
      "Next": "Step2"
    },
    "Step2": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.simple_step_function_lambda_2.arn}",
      "End": true
    }
  }
}
EOF
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda_zip_inline_1" {
  type        = "zip"
  output_path = "/tmp/lambda_zip_inline1.zip"
  source {
    content  = <<EOF
def test(event, context):
  print("Test called")
  event["apples"] = "1"
  return event
EOF
    filename = "main.py"
  }
}

data "archive_file" "lambda_zip_inline_2" {
  type        = "zip"
  output_path = "/tmp/lambda_zip_inline2.zip"
  source {
    content  = <<EOF
def test(event, context):
  print("Test called")
  event["oranges"] = "2"
  return event
EOF
    filename = "main.py"
  }
}

resource "aws_lambda_function" "simple_step_function_lambda_1" {
  function_name = "simple-step-function-step1"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.test"
  runtime       = "python3.9"
  filename         = data.archive_file.lambda_zip_inline_1.output_path
  source_code_hash = data.archive_file.lambda_zip_inline_1.output_base64sha256
}

resource "aws_lambda_function" "simple_step_function_lambda_2" {
  function_name = "simple-step-function-step2"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.test"
  runtime       = "python3.9"
  filename         = data.archive_file.lambda_zip_inline_2.output_path
  source_code_hash = data.archive_file.lambda_zip_inline_2.output_base64sha256
}