import boto3
import json
import time
from decimal import Decimal
import os

# Ressourcen definieren
dynamodb = boto3.resource('dynamodb')
resume_table_name = os.environ.get('VISITOR_TABLE')
ip_table_name = os.environ.get('IP_TABLE')

resume_table = dynamodb.Table(resume_table_name)
ip_table = dynamodb.Table(ip_table_name)

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError

def lambda_handler(event, context):
    request_context = event.get('requestContext', {})
    http_info = request_context.get('http', {})
    ip_address = http_info.get('sourceIp')
    
    if not ip_address:
        headers = event.get('headers', {})
        ip_address = headers.get('X-Forwarded-For', '').split(',')[0]

    if not ip_address:
        # Falls lokal getestet wird oder IP fehlt
        ip_address = "unknown"

    # 2. Prüfen, ob die IP in den letzten 24h schon da war
    check_ip = ip_table.get_item(Key={'IP': ip_address})
    
    if 'Item' not in check_ip:
        # IP ist neu! -> Counter erhöhen
        response = resume_table.update_item(
            Key={'MetricName': 'visitor_count'}, # Stelle sicher, dass dein Key hier stimmt!
            UpdateExpression="SET VisitorCount = if_not_exists(VisitorCount, :zero) + :inc",
            ExpressionAttributeValues={':zero': 0, ':inc': 1},
            ReturnValues="UPDATED_NEW"
        )
        
        # IP in der Sperr-Tabelle registrieren (mit 24h Ablaufdatum)
        ttl_value = int(time.time()) + (24 * 60 * 60) # Jetzt + 24 Stunden
        ip_table.put_item(Item={
            'IP': ip_address,
            'TimeToLive': ttl_value
        })
        
        message = "Counter increased"
        new_count = response.get('Attributes', {}).get('VisitorCount', 0)
    else:
        # IP war heute schon da -> Nur aktuellen Stand holen ohne zu erhöhen
        res = resume_table.get_item(Key={'MetricName': 'visitor_count'})
        new_count = res.get('Item', {}).get('VisitorCount', 0)
        message = "IP already visited today"

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "https://fabiano-petillo.dev",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps({
            "count": new_count,
            "message": message,
            "ip": ip_address
        }, default=decimal_default)
    }