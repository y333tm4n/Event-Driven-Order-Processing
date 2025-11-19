# Event-Driven Order Processing System

A serverless order processing system using AWS services, built with Terraform and tested locally with LocalStack.

## Architecture

**Services:**
- **API Gateway** - REST API endpoint
- **Lambda** - 3 functions (create, process, generate invoice)
- **DynamoDB** - Order storage
- **SQS** - Message queue for async processing
- **SNS** - Notifications
- **S3** - Invoice storage

## Features

- RESTful API for orders
- Async processing with retry logic
- Customer notifications
- Invoice generation
- Infrastructure as Code (Terraform)
- Local testing with LocalStack

## Prerequisites

- Docker
- Terraform >= 1.0
- AWS CLI
- Python 3.11+

## Setup

### 1. Start LocalStack

```bash
docker run -d --name localstack -p 4566:4566 localstack/localstack
```

Verify it's running:
```bash
curl http://localhost:4566/_localstack/health
```

### 2. Configure AWS CLI

Ensure your AWS CLI is configured with dummy credentials for LocalStack:

```bash
# ~/.aws/credentials
[default]
aws_access_key_id = test
aws_secret_access_key = test

# ~/.aws/config
[default]
region = us-east-1
```

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

Save the API ID from the output:
```bash
terraform output api_id
```

## Usage

### Create an Order

```bash
curl -X POST "http://localhost:4566/restapis/<API_ID>/dev/_user_request_/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "John Doe",
    "customer_email": "john@example.com",
    "items": [
      {"name": "Laptop", "quantity": 1, "price": 999.99},
      {"name": "Mouse", "quantity": 2, "price": 25.50}
    ]
  }'
```

Replace `<API_ID>` with your API Gateway ID from terraform output.

### Check Order Status

```bash
aws dynamodb scan \
  --table-name order-processing-orders \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

### View Invoices

```bash
aws s3 ls s3://order-processing-invoices-dev/invoices/ \
  --endpoint-url http://localhost:4566 \
  --region us-east-1
```

## 📁 Project Structure

```
.
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Root module
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── providers.tf               # Provider configuration
│   └── modules/                   # Reusable modules
│       ├── api_gateway/           # API Gateway module
│       ├── dynamodb/              # DynamoDB module
│       ├── lambda/                # Lambda module
│       ├── s3/                    # S3 module
│       ├── sns/                   # SNS module
│       └── sqs/                   # SQS module
│
├── src/                           # Lambda function source code
│   ├── create_order/
│   │   ├── handler.py
│   │   └── requirements.txt
│   ├── process_order/
│   │   ├── handler.py
│   │   └── requirements.txt
│   ├── generate_invoice/
│   │   ├── handler.py
│   │   └── requirements.txt
│   └── shared/
│       └── utils.py               # Shared utilities
│
└── README.md
```

## 🔄 Order Processing Flow

1. **Order Creation**
   - Client sends POST request to API Gateway
   - `create_order` Lambda validates and saves order to DynamoDB
   - Order status: `pending`
   - Message sent to SQS queue

2. **Order Processing**
   - `process_order` Lambda triggered by SQS message
   - Order status updated to `processing`
   - Payment processing simulation
   - Order status updated to `completed` or `failed`
   - SNS notification sent to customer

3. **Invoice Generation** (Optional)
   - Invoice generated in text format
   - Uploaded to S3 bucket
   - Invoice URL stored in DynamoDB

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy -auto-approve
```

Stop LocalStack:
```bash
docker stop localstack
docker rm localstack
```

**Note**: This project uses LocalStack for local development. No actual AWS resources are created, ensuring zero AWS costs during development.