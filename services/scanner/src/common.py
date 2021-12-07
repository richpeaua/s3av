from datetime import datetime
import json
import logging
import traceback
import urllib.request

import boto3

from configs import config

BOTO_SESSIONS = {}


def timestamp_now():
    """Return timestamp of function execution in UTC"""

    return datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')


def setup_boto_session(account_id, region_name):
    """Create and cache boto3 session

    Args:
        account_id (str): AWS account ID
        region_name (str): AWS region
    Raises:
        err: unable to assume role from another AWS account
        Exception: 
    """

    cache_key = ''.join([account_id, str(region_name)])

    if account_id == config.AWS_ACCOUNT:
        BOTO_SESSIONS[cache_key] = boto3.Session(region_name=region_name)
    else:
        # if `account_id` is not equal to the aws account in the lambda configuration then
        # attempt to assume role in `account_id`
        logging.info(f'Assuming role from another AWS account: {account_id} Region: {region_name}')
        current_session = get_boto_session(config.AWS_ACCOUNT)
        boto_sts = current_session.client('sts')

        try:
            response = boto_sts.assume_role(RoleArn=f'arn:aws:iam::{account_id}:role/s3-virus-scanner', RoleSessionName='newsession')
        except Exception as err:
            logging.error(f'Error assuming cross account role. Make sure required IAM role and policies are created in {account_id} account')
            logging.error(traceback.format_exc())
            raise err
        else:
            if response['ResponseMetadata']['HTTPStatusCode'] != 200:
                logs_extra = {'http_code': response['ResponseMetadata']['HTTPStatusCode']}
                logging.error('Error assuming cross account role. Http response is not 200', extra=logs_extra)
                raise Exception('Error publishing to SNS. Return code is not 200')
            logging.info(f'Cross account role assumed: {account_id}')

            BOTO_SESSIONS[cache_key] = boto3.Session(aws_access_key_id=response['Credentials']['AccessKeyId'],
                                                      aws_secret_access_key=response['Credentials']['SecretAccessKey'],
                                                      aws_session_token=response['Credentials']['SessionToken'],
                                                      region_name=region_name)

            client = BOTO_SESSIONS[cache_key].client('sts')
            account_id = client.get_caller_identity()["Account"]
            print("New Account:", account_id, 'region:', str(region_name))


def get_boto_session(account_id, region_name=None):
    """Return a cached boto3 session

    Args:
        account_id (str): AWS account ID
        region_name (str): AWS region
    Returns:
        obj`boto3.Session`: boto3 session object that can be used to create clients to various AWS resources
    """

    logging.info(f'Get new boto session: AWS Account: {account_id} Region: {region_name}')

    cache_key = ''.join([account_id, str(region_name)])
    if cache_key not in BOTO_SESSIONS:
        setup_boto_session(account_id, region_name)

    return BOTO_SESSIONS[cache_key]


def get_appconfig():
    logging.info('Fetching application configs from local AppConfig extension')
    try:
        config_request = urllib.request.urlopen(config.APPCONFIG_EXT_URL)
    except Exception as err:
        logging.error('Could not fetch configs from Appconfig, check lambda IAM policy')
        logging.error(err)
        raise err

    logging.info('Application configs fetched successfully')
    app_config = json.loads(config_request.read())
    return app_config
