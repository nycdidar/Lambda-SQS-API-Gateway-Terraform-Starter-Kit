Lambda SQS API Gateway Terraform Template / Starter Kit
=================================

## Required Permissions
- Lambda access to read and delete SQS messages
- API Gateway to invoke lambda function
- Trigger lambda on SQS message receive (event_source_mapping)
- Cloudwatch logs
- Lambda access to Secret Manager


## Deploy Steps


#### Change Secret Name Before Each Deploy
```
secret_manager_name            = "my-secret-name"
```

#### Install Python Dependencies (locally). For Python only
```cd lambda```
```pip install -r requirements.txt -t ./```
```cd ..```

#### Deploy !!!!
```
terraform init
terraform apply -var-file="ENV.tfvars"
```

### Destroy Instances
```
terraform destroy -var-file="ENV.tfvars"
```

### Troubleshooting
If there is any lambda permission error
```chmod -R 644 lambda```

