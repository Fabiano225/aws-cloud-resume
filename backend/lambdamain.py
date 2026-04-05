import boto3
import json
from decimal import Decimal

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError

# Define the DynamoDB table that Lambda will connect to
table_name = "Resume"

# Create the DynamoDB resource
dynamo = boto3.resource('dynamodb').Table(table_name)

def update(payload):
    return dynamo.update_item(Key=payload['Key'], UpdateExpression="SET VisitorCount = if_not_exists(VisitorCount, :zero) + :inc", 
    ExpressionAttributeValues={
    ':zero': 0, 
    ':inc': 1
    },
    ReturnValues="UPDATED_NEW"
)

operations = {
    'update': update
}

def lambda_handler(event, context):
    body = event
    if 'body' in event:
        body = json.loads(event['body'])
    
    operation = body.get('operation')
    payload = body.get('payload')
    
    if operation in operations:
        response = operations[operation](payload)
        
        # Format API Response
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*" # Allow Browser access (CORS)
            },
            "body": json.dumps(response, default=decimal_default)
        }
        
    return {
        "statusCode": 400,
        "body": json.dumps({"error": "Unrecognized operation"})
    }