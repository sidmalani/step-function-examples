resource "aws_sfn_state_machine" "poly_state_machine" {
  name     = "poly-step-function"
  role_arn = aws_iam_role.simple_step_function_role.arn

  definition = <<EOF
{
  "Comment": "Polymorphic example",
  "StartAt": "CallLambda",
  "States": {
    "CallLambda":{
      "Type":"Task",
      "Resource":"arn:aws:states:::lambda:invoke",
      "Parameters":{
        "FunctionName":"${aws_lambda_function.poly_function.function_name}",
        "Qualifier.$": "$.client"
      },
      "End":true
    }
  }
}
EOF
}

data "archive_file" "poly_1" {
  type        = "zip"
  output_path = "/tmp/poly1.zip"
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

# Check readme
resource "aws_lambda_function" "poly_function" {
  function_name    = "poly-step-function-step"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "main.test"
  runtime          = "python3.9"
  filename         = data.archive_file.poly_1.output_path
  source_code_hash = data.archive_file.poly_1.output_base64sha256
  publish          = true
}
