#--------------------------------------------------------------
# Dev Env Variables
#--------------------------------------------------------------

app_prefix                     = "/aws/dev/my-dept"
app_name                       = "My-Awesome-App"
app_iam_role                   = "arn:aws:iam::XXXXXXXXXXXX:role/my-role-name"
environment                    = "dev"
aws_profile                    = "default"
aws_region                     = "us-east-1"

## ** THIS MUST BE CHANGED IN EACH NEW DEPLOY ****
secret_manager_name            = "my-secret-name"

## Source SQS Config
source_sqs_delay_time          = 28
source_sqs_retention           = 86400

## API Gateway Config
api_env                        = "prod"
api_gateway_path_part          = "hello"

## Tags For Tracking
product                        = "Awesome Product"
project                        = "Awesome Project"
departmemt_code                = "111111111"
owner                          = "John Doe"

