import json
import os
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb', endpoint_url=os.environ.get('AWS_ENDPOINT_URL'))
sns = boto3.client('sns', endpoint_url=os.environ.get('AWS_ENDPOINT_URL'))
lambda_client = boto3.client('lambda', endpoint_url=os.environ.get('AWS_ENDPOINT_URL'))

DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    """
    Process orders from SQS queue, updates status, and triggers invouice generation
    """

    try:
        # process each sqs message
        for record in event['Records']:
            # parse the order from sqs message
            order = json.loads(record['body'])
            order_id = order['order_id']

            print(f"Processing order: {order_id}")

            # updated order status to 'processing'
            table = dynamodb.Table(DYNAMODB_TABLE)
            table.update_item(
                Key = {'order_id': order_id},
                UpdateExpression = 'SET #status = :status, updated_at = :updated_at',
                ExpressionAttributeNames = {
                    '#status': 'status'
                },
                ExpressionAttributeValues = {
                    ':status': 'processing',
                    ':updated_at': datetime.utcnow().isoformat() 
                }
            )

            # simulate order processing format (payment, inventory check, etc.)
            processing_success = process_payment(order)

            if processing_success:
                # update order status to 'completed'
                table.update_item(
                    Key = {'order_id': order_id},
                    UpdateExpression = 'SET #status = :status, updated_at = :updated_at',
                    ExpressionAttributeNames = {
                        '#status': 'status'
                    },
                    ExpressionAttributeValues = {
                        ':status': 'completed',
                        ':updated_at': datetime.utcnow().isoformat()
                    }
                )
                
                # send notification via sns
                send_notification(order)

                print(f'Order {order_id} processed successfully')
            
            else:
                # updated order status to 'failed'
                table.update_item(
                    Key={'order_id': order_id},
                    UpdateExpression = 'SET #status = :status, updated_at = :updated_at',
                    ExpressionAttributeNames = {
                        '#status': 'status'
                    },
                    ExpressionAttributeValues = {
                        ':status': 'failed',
                        ':updated_at': datetime.utcnow().isoformat()
                    }
                )

                print(f'Order {order_id} processing failed')
            
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Orders processed successfully'})
        }
    
    except Exception as e:
        print(f'Error processing orders: {str(e)}')
        raise e

def process_payment(order):
    """
    simulate payment processing
    if ever used, this can be integrated with a payment gateway
    """

    # simulate successful payment for all orders
    # this part here integrated a payment API if ever used in production
    print(f"Processing payment for order {order['order_id']}")
    print(f"Amount: ${order['total_price']}")
    return True

def send_notification(order):
    """
    Send order confirmation notification via SNS
    """
    try:
        message = f"""
            Order Confirmation

            Order ID: {order['order_id']}
            Customer: {order['customer_name']}
            Email: {order['customer_email']}
            Total: ${order['total_price']}
            Status: Completed

            Items:
            """
        for item in order['items']:
            message += f"\n- {item.get('name', 'Unknown')} x {item.get('quantity', 1)} = ${item.get('price', 0) * item.get('quantity', 1)}"
        
        message += "\n\nThank you for your order!"
        
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"Order Confirmation - {order['order_id']}",
            Message=message
        )
        
        print(f"Notification sent for order {order['order_id']}")
        
    except Exception as e:
        print(f"Error sending notification: {str(e)}")
        # Don't raise the exception - we don't want to fail the entire process if notification fails