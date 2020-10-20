#
# Lambda SQS API Gateway Starter Kit
#

import boto3
import os
from botocore.exceptions import ClientError

AWS_SQS_QUEUE_URL = os.getenv('AWS_SQS_QUEUE_URL', '')
AWS_REGION = os.getenv('REGION', 'us-east-1')

QUEUE_QTY = 10
resultObject = {}

sqs = boto3.client("sqs", region_name=AWS_REGION)

def lambda_handler(event, context):
    return {"statusCode": 200, "body": "Hello world"}

