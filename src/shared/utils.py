import json
import decimal

class DecimalEncoder(json.JSONEncoder):
    """
    Helper class to convert dynamodb decimal types to json
    """

    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def format_response(status_code, body, headers=None):
    """
    Format api gateway response
    """
    response = {
        'statusCode': status_code,
        'headers': headers or {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }
    return response