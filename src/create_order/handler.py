import json
import os
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb', endpoint_url=os.environ.get('AWS_ENDPOINT_URL'))
sqs = boto3.client('sqs', endpoint_url=os.environ.get('AWS_ENDPOINT_URL'))

DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
SQS_QUEUE_URL =  os.environ['SQS_QUEUE_URL']

def lambda_handler(event, context):
    """
    This allows new order/s, saves to dynamodb and sends to sqs for processing
    """

    try:
        # parse request body
        body = json.loads(event.get('body', '{}'))

        # validate required fields
        required_fields = ['customer_name', 'customer_email', 'items']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400, 
                    'body': json.dumps({'error': f'Missing required field: {field}'})
                }
        
        # generate order id and timestamp
        order_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()

        # calculate the total price and convert to Decimal
        total_price = sum(item.get('price',0) * item.get('quantity', 1)
                          for item in body['items'])
        
        # convert float values to Decimal for DynamoDB
        items_with_decimal = []
        for item in body['items']:
            items_with_decimal.append({
                'name': item.get('name', ''),
                'quantity': item.get('quantity', 1),
                'price': Decimal(str(item.get('price', 0)))
            })
        
        # create order object
        order = {
            'order_id': order_id,
            'customer_name': body['customer_name'],
            'customer_email': body['customer_email'],
            'items': items_with_decimal,
            'total_price': Decimal(str(total_price)),
            'status': 'pending',
            'created_at': timestamp,
            'updated_at': timestamp
        }

        # save to dynamodb
        table = dynamodb.Table(DYNAMODB_TABLE)
        table.put_item(Item=order)

        # send to sqs for processing (convert Decimal back to float for JSON)
        order_for_sqs = {
            'order_id': order_id,
            'customer_name': body['customer_name'],
            'customer_email': body['customer_email'],
            'items': body['items'],  # Use original items with floats
            'total_price': float(total_price),
            'status': 'pending',
            'created_at': timestamp,
            'updated_at': timestamp
        }
        
        sqs.send_message(
            QueueUrl = SQS_QUEUE_URL,
            MessageBody = json.dumps(order_for_sqs)
        )

        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json'
            },

            'body': json.dumps({
                'message': 'Order created successfully',
                'order_id': order_id,
                'total_price': float(total_price)
            })
        }

    except Exception as e:
        print(f'Error creating order: {str(e)}')
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal Server Error'})
        }
