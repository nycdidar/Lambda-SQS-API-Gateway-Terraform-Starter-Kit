#
# Lambda SQS Template
# Deploy Instruction:
#
# terraform init
# terraform apply -var-file="dev.tfvars"
#

## ********************************
## *** Variables ********
## ********************************

## AWS Config
variable "app_name" { }
variable "app_prefix" { }
variable "environment" { }
variable "aws_profile" { }
variable "aws_region" { }
variable "secret_manager_name" { }
#variable "app_iam_role" { }

## API Gateway Config
variable "api_env" { }
variable "api_gateway_path_part" { }

## SQS Config
variable "source_sqs_delay_time" { }
variable "source_sqs_retention" { }

## Tags For Tracking
variable "product" { }
variable "project" { }
variable "departmemt_code" { }
variable "owner" { }

## **************************************
provider "aws" {
  region     = "${var.aws_region}"
  profile = "${var.aws_profile}"
  #allowed_account_ids = ["${var.aws_account_id}"]
}

data "aws_caller_identity" "current" { }


## ********************************
## *** ROLES AND POLICIES  ********
## ********************************

resource "aws_iam_role" "app_iam_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "app_iam_role" {
  policy_arn = "${aws_iam_policy.app_iam_role.arn}"
  role = "${aws_iam_role.app_iam_role.name}"
}

resource "aws_iam_policy" "app_iam_role" {
  policy = "${data.aws_iam_policy_document.app_iam_role.json}"
}

data "aws_iam_policy_document" "app_iam_role" {
  statement {
    sid       = "AllowSQSPermissions"
    effect    = "Allow"
    resources = ["${aws_sqs_queue.my_sqs_handler.arn}"]

    actions = [
      "sqs:SendMessage",
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }

  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["${aws_lambda_function.my_lambda_handler.arn}"]
    actions   = ["lambda:InvokeFunction"]
  }

  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:us-east-1:*:*"]
    actions   = ["logs:CreateLogGroup"]
  }
  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:us-east-1:*:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

}

## ********************************
## *** Secret Manager Configs ********
## ********************************
# # Name below must be unique and should be re-used if it's previously deleted.
# resource "aws_secretsmanager_secret" "mySQSSecret" {
#  name = "${var.app_prefix}/${var.secret_manager_name}"
#  description = "My Secret Credentials"
# }

# resource "aws_secretsmanager_secret_version" "mySQSSecret" {
#  secret_id     = "${aws_secretsmanager_secret.mySQSSecret.id}"
#  secret_string = "{\"my_custom_url\":\"${var.my_custom_url}\",\"my_custom_api_key\":\"${var.my_custom_api_key}\"}"
# }


## ********************************
## *** SOURCE SQS Configs ********
## ********************************
resource "aws_sqs_queue" "my_sqs_handler" {
 name                      = "${var.app_name}"
 delay_seconds             = "${var.source_sqs_delay_time}"
 max_message_size          = 262144
 message_retention_seconds = "${var.source_sqs_retention}"
 receive_wait_time_seconds = 0
 visibility_timeout_seconds = 30

  #fifo_queue                  = true
  #content_based_deduplication = true

  #redrive_policy = jsonencode({
  #  deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
  #  maxReceiveCount     = 4
  #})

  tags = {
    Product = "${var.product}"
    Project = "${var.project}"
    Department_Code = "${var.departmemt_code}"
    Owner = "${var.owner}"
  }
}

## ********************************
## *** Lambda Configs ********
## ********************************

data "archive_file" "zip" {
  type        = "zip"
  #source_file = "my_lambda_handler.py"
  source_dir = "./lambda"
  output_path = "my_lambda_handler.zip"
}

resource "aws_lambda_function" "my_lambda_handler" {
  function_name = "${var.app_name}-my_lambda_handler"
  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  #role    = "${aws_iam_role.app_iam_role.arn}"
  #role    = "${var.app_iam_role}"
  role     = "${aws_iam_role.app_iam_role.arn}"
  handler = "my_lambda_handler.lambda_handler"
  runtime = "python3.7"

  timeout = 30
  memory_size = 128

  environment {
    variables = {
      AWS_SQS_QUEUE_URL = aws_sqs_queue.my_sqs_handler.id
    }
  }

  tags = {
    Product = "${var.product}"
    Project = "${var.project}"
    Department_Code = "${var.departmemt_code}"
    Owner = "${var.owner}"
  }

}

## ********************************
## *** Lambda Event Trigger *******
## ********************************
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
 batch_size       = 10
 event_source_arn =  "${aws_sqs_queue.my_sqs_handler.arn}"
 enabled          = true
 function_name    =  "${aws_lambda_function.my_lambda_handler.arn}"
}

## ********************************
## *** API Gateway Configs ********
## ********************************
# Now, we need an API to expose those functions publicly
resource "aws_api_gateway_rest_api" "my_api_gateway_handler" {
  name = "${var.app_name}"
  tags = {
    Product = "${var.product}"
    Project = "${var.project}"
    Department_Code = "${var.departmemt_code}"
    Owner = "${var.owner}"
  }

}

# The API requires at least one "endpoint", or "resource" in AWS terminology.
resource "aws_api_gateway_resource" "my_api_gateway_resource_handler" {
  rest_api_id = "${aws_api_gateway_rest_api.my_api_gateway_handler.id}"
  parent_id   = "${aws_api_gateway_rest_api.my_api_gateway_handler.root_resource_id}"
  path_part   = "${var.api_gateway_path_part}"
}

#
module "my_module_api_gateway_one" {
  source      = "./trfm_modules/api"
  statement_id = "AllowExecutionFromApiGateway"
  rest_api_id = "${aws_api_gateway_rest_api.my_api_gateway_handler.id}"
  resource_id = "${aws_api_gateway_resource.my_api_gateway_resource_handler.id}"
  method      = "POST"
  path        = "${aws_api_gateway_resource.my_api_gateway_resource_handler.path}"
  lambda      = aws_lambda_function.my_lambda_handler.function_name
  region      = "${var.aws_region}"
  account_id  = "${data.aws_caller_identity.current.account_id}"
}

# 
resource "aws_api_gateway_deployment" "my_api_gateway_deployment_handler" {
  rest_api_id = "${aws_api_gateway_rest_api.my_api_gateway_handler.id}"
  stage_name  = "${var.api_env}"
  lifecycle {
    create_before_destroy = true
  }
  description = "Deploy methods: ${module.my_module_api_gateway_one.http_method} "
}

# To Add API Key
resource "aws_api_gateway_usage_plan" "my_aws_usage_plan" {
  name = "${var.app_name}-Usage"
  depends_on = [
    aws_api_gateway_rest_api.my_api_gateway_handler
  ]
}

resource "aws_api_gateway_api_key" "my_api_ky_handler" {
  name = "${var.app_name}-my_api_ky_handler"
}

resource "aws_api_gateway_usage_plan_key" "my_usage_plan" {
  key_id        = aws_api_gateway_api_key.my_api_ky_handler.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.my_aws_usage_plan.id
}


output "Lambda_Name" {
 value = aws_lambda_function.my_lambda_handler.function_name
}

output "API_Gateway" {
  description = "Deployment invoke url"
  value       = aws_api_gateway_deployment.my_api_gateway_deployment_handler.invoke_url
}


# Import API Key
# terraform import aws_api_gateway_usage_plan_key.my_api_ky_handler 12345abcde/zzz
