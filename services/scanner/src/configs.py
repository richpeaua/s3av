from os import environ
import os.path


class Config(object):
    """Config object for the `scanner` lambda function"""

    AWS_ACCOUNT = environ.get('AWS_ACCOUNT')

    # Local data directory to download s3 files and store them fo scanning
    PATH_FILES_DL_LOCAL = environ.get('PATH_FILES_DL_LOCAL', '/tmp')

    # S3
    S3_CONNECTION_TIMEOUT = environ.get('S3_CONNECTION_TIMEOUT', 10)
    S3_MAX_ATTEMPTS = environ.get('S3_CONNECTION_TIMEOUT', 3)

    # SNS
    SNS_CONN_TIMEOUT = environ.get('SNS_CONN_TIMEOUT', 10)
    SNS_CONN_MAX_ATTEMP = environ.get('SNS_CONN_MAX_ATTEMP', 3)

    # ClamAV
    PATH_CLAMAV = environ.get('PATH_CLAMAV', '/var/lib/clamav')
    VS_USER = environ.get('VS_USER', 'root')
    VS_PATH_FRESHCLAM_CONF = environ.get('VS_PATH_FRESHCLAM_CONF', os.path.join(PATH_CLAMAV, 'freshclam.conf'))
    VS_PATH_DB = environ.get('VS_PATH_DB', os.path.join("/tmp", 'clamav_db'))

    # S3 Object Tag Keys
    VS_S3_OBJ_TAG_STATUS = 'S3AVScanStatus'
    VS_S3_OBJ_TAG_SIGNATURE = 'S3AVVirusSignature'
    VS_S3_OBJ_TAG_TIMESTAMP = 'S3AVScanTimestamp'

    # Service Confg
    PATH_SRVC_CONFIG = environ.get('PATH_SRVC_CONFIG', './service_config.json')

config = Config()
