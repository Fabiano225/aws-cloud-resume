import json
import boto3

def lambda_handler(event, context   ):
    client = boto3.client('dynamodb')

    #GET Item
    response = client.get_item(
        TableName='Resume',
        Key={
            'Visitor count': {
                'N': '0'
            }
        }
    )

    #PUT Item
    put = client.put_item(
        TableName='Resume',
        Item={
            'Visitor count': {
                'N': '1'
            }
        }
    )

    return put
    # return response