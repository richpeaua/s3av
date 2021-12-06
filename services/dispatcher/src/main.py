import logging
import traceback
import gzip
import base64
import requests
import json
import boto3
from os import environ
from botocore.config import Config

from logger import setup_logger


SNS_TOPIC_ARN = environ['SNS_TOPIC_ARN']
SNS_CONN_MAX_ATTEMP = environ.get('SNS_CONN_MAX_ATTEMP', 3)
SNS_CONN_TIMEOUT = environ.get('SNS_CONN_TIMEOUT', 10)

APPCONFIG_APP_NAME = environ.get('APPCONFIG_APP')
APPCONFIG_ENV = environ.get('APPCONFIG_ENV')
APPCONFIG_EXT_URL = f'http://localhost:2772/applications/{APPCONFIG_APP_NAME}/environments/{APPCONFIG_ENV}/configurations/{APPCONFIG_APP_NAME}'

AWS_CONFIG = Config(connect_timeout=SNS_CONN_TIMEOUT, retries={'max_attempts': SNS_CONN_MAX_ATTEMP})
sns = boto3.client('sns', config=AWS_CONFIG)

def get_appconfig():
    logging.debug('Fetching application configs from local AppConfig extension')
    try:
        config_request = requests.get(APPCONFIG_EXT_URL)
    except Exception as err:
        logging.error('Could not fetch configs from Appconfig, check lambda IAM policy')
        logging.error(err)
        raise err

    logging.debug('Application configs fetched from AppConfig')
    app_config = json.loads(config_request.content)
    return app_config

def parse_cloudwatch_event(event):
    if 'awslogs' not in event:
        logging.error('Unsupported event type. We only support AWS CloudWatch logs event type')
        logging.error(repr(event))
        raise TypeError('Unsupported event type. We only support AWS CloudWatch logs event type')

    data = json.loads(gzip.decompress(base64.b64decode(event['awslogs']['data'])))
    logs_extra = {'batch_size': len(data['logEvents']), 'log_stream': data['logStream']}
    logging.info('dispatching', extra=logs_extra)
    return data['logEvents']


def msg_from_cloudtrail_event(event):
    if event.get('eventType') != 'AwsApiCall':
        logging.error('Unsupported log type. We only support CloudTrail logs')
        logging.error(repr(event))
        raise TypeError('Unsupported log type. We only support CloudTrail logs')

    if event['eventName'] not in ('PutObject', 'CompleteMultipartUpload'):
        # We will use filter pattern for CloudWatch subscription so we shouldn't receive any other events
        logging.error(f'Unsupported S3 event. We only support PutObject and CompleteMultipartUpload not {event["eventName"]}')
        raise TypeError(f'Unsupported S3 event. We only support PutObject and CompleteMultipartUpload not {event["eventName"]}')

    msg = {}

    msg['event_id'] = event['eventID']
    msg['account'] = event['recipientAccountId']
    msg['region'] = event['awsRegion']
    msg['bucket'] = event['requestParameters']['bucketName']
    msg['key'] = event['requestParameters']['key']
    msg['time'] = event['eventTime']

    logging.info('New message received', extra={'cmd': 'new_msg', 'event_id': msg["event_id"], 'account': msg['account'], 'region': msg['region'], 'bucket': msg['bucket'], 'key': msg['key']})
    return msg


def publish_message(msg):
    logging.info('Publishing to SNS', extra={'cmd': 'sns_publishing', 'event_id': msg["event_id"], 'account': msg['account'], 'bucket': msg['bucket'], 'key': msg['key']})
    try:
        response = sns.publish(TopicArn=SNS_TOPIC_ARN, Message=json.dumps(msg), Subject='Scan', MessageStructure='string')
    except Exception as err:
        logging.error('Error publishing message into SNS', extra={'cmd': 'sns_publish_error', 'event_id': msg["event_id"], 'account': msg['account'], 'bucket': msg['bucket'], 'key': msg['key']})
        logging.error(traceback.format_exc())
        raise err
    else:
        if response['ResponseMetadata']['HTTPStatusCode'] != 200:
            logs_extra = {'event_id': msg["event_id"], 'http_code': response['ResponseMetadata']['HTTPStatusCode']}
            logging.error('publish_sns_error', extra=logs_extra)
            raise Exception('Error publishing to SNS. Return code is not 200')
        logging.info('Message published into SNS', extra={'cmd': 'sns_published', 'event_id': msg["event_id"], 'account': msg['account'], 'bucket': msg['bucket'], 'key': msg['key']})


def main(event):
    for cloudtrail_event in parse_cloudwatch_event(event):
        cloudtrail_event = json.loads(cloudtrail_event['message'])
        msg = msg_from_cloudtrail_event(cloudtrail_event)
        
        app_config = get_appconfig()
        scan_scope = app_config.get('scan_scope')
        enabled_accounts = scan_scope['accounts']
        if msg['account'] in enabled_accounts:
            publish_message(msg)
        else:
            logging.info('Account is not enabled', extra={'cmd': 'account_disabled', 'event_id': msg["event_id"], 'account': msg['account'], 'bucket': msg['bucket'], 'key': msg['key']})


def lambda_handler(event, context):
    setup_logger(aws_request_id=context.aws_request_id)

    try:
        main(event)
        return 'done'
    except Exception as err:
        logging.error('Error while dispatching!')
        # logging.error(repr(event))
        logging.error(traceback.format_exc())
        raise err
