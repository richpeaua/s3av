import logging
import traceback
import json
import requests
import boto3
from os import environ
from botocore.config import Config

from logger import setup_logger


ASM_SECRET_NAME = environ['ASM_SECRET_NAME']
ASM_CONN_MAX_ATTEMP = environ.get('ASM_CONN_MAX_ATTEMP', 3)
ASM_CONN_TIMEOUT = environ.get('ASM_CONN_TIMEOUT', 10)
ORG_CONN_MAX_ATTEMP = environ.get('ORG_CONN_MAX_ATTEMP', 3)
ORG_CONN_TIMEOUT = environ.get('ORG_CONN_TIMEOUT', 10)

SLACK_HEADER = {"Content-type": "application/json"}

APPCONFIG_APP_NAME = environ.get('APPCONFIG_APP')
APPCONFIG_ENV = environ.get('APPCONFIG_ENV')
APPCONFIG_EXT_URL = f'http://localhost:2772/applications/{APPCONFIG_APP_NAME}/environments/{APPCONFIG_ENV}/configurations/{APPCONFIG_APP_NAME}'

session = boto3.session.Session()


def get_secret(name=None):
    AWS_CONFIG = Config(connect_timeout=ASM_CONN_TIMEOUT, retries={'max_attempts': ASM_CONN_MAX_ATTEMP})
    client = session.client(service_name='secretsmanager', config=AWS_CONFIG)

    try:
        response = client.get_secret_value(SecretId=ASM_SECRET_NAME)
    except Exception as err:
        logging.error('Error connecting AWS ASM', extra={'secret_name': ASM_SECRET_NAME})
        logging.error(traceback.format_exc())
        raise err
    else:
        if name:
            try:
                return json.loads(response['SecretString'])[name]
            except Exception as err:
                logging.error(f"Secret key '{name}' doesn't exists in ASM", extra={'secret_name': ASM_SECRET_NAME})
                logging.error(traceback.format_exc())
                raise err
        else:
            return json.loads(response['SecretString'])

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

def send_to_slack(event):
    print(event)
    app_config = get_appconfig()
    aws_accounts_dict = app_config.get('aws_accounts')
    aws_account = aws_accounts_dict.get(event['account'], event['account'])
    if event['status'] == 'CLEAN':
        status = ''
        signature = ""
    else:
        status = ':o:'
        signature = f":rotating_light: *{event['signature']}*"

    msg = f"{status} :cloud: {aws_account} :file_cabinet: {event['bucket']}  :file_folder: _{event['key']}_ {signature}"

    payload = {"text": msg}
    slack_webhook = get_secret('SLACK_WEBHOOK')
    response = requests.post(slack_webhook, headers=SLACK_HEADER, data=json.dumps(payload).encode("utf-8"))

    if response.status_code != 200:
        raise Exception(
            'Request to slack returned an error %s, the response is:\n%s'
            % (response.status_code, response.text)
        )


def main(event):
    assert len(event['Records']) == 1
    assert event['Records'][0]['EventSource'] == 'aws:sns'

    sns_event = json.loads(event['Records'][0]['Sns']['Message'])

    send_to_slack(sns_event)


def lambda_handler(event, context):
    setup_logger(aws_request_id=context.aws_request_id)

    try:
        main(event)
        return 'done'
    except Exception as err:
        logging.error('Error!')
        # logging.error(repr(event))
        logging.error(traceback.format_exc())
        raise err
