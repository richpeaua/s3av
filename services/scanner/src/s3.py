import os.path
import urllib.parse
import logging
import time
import copy
from uuid import uuid4
from pathlib import Path

from botocore.client import Config as Config_boto3

from configs import config
from common import get_boto_session

logger = logging.getLogger()


class S3File(object):
    """S3File object represents a file stored within an S3 bucket

    This object parses an SNS message of an S3 push event that contains, among other items, a filename 
    and the S3 bucket in which the file resides and then maps itself to said file for further handling and processing.

    Args:
        event_data (json): SNS message of an S3 push event
    """

    def __init__(self, event_data) -> None:
        super().__init__()

        self._event_data = event_data
        self._s3_resource = None
        self._s3_object = None
        self._s3_object_tags = None
        self._local_filename = None

    @property
    def key(self):
        """`str`: S3 object key/path"""

        # AWS replace spaces with plus sign in S3 Event Records
        return urllib.parse.unquote_plus(self._event_data['key'], encoding='utf-8')

    @property
    def bucket(self):
        """`str`: S3 bucket name"""

        return self._event_data['bucket']

    @property
    def aws_account(self):
        """`str`: AWS account owning the S3 bucket"""

        return self._event_data['account']

    @property
    def region(self):
        """`str`: AWS region where S3 bucket lives"""

        return self._event_data['region']

    @property
    def size(self):
        """`int`: file size"""

        return self.s3_obj.content_length

    @property
    def event_id(self):
        """`str`: SNS message event id"""

        return self._event_data['event_id']

    @property
    def event_time(self):
        """`str`: ISO formatted timestamp of when the S3 push event was published"""

        return self._event_data['time']

    @property
    def s3_resource(self):
        """obj`S3.ServiceResource`: S3 resource object"""

        if not self._s3_resource:
            logger.info(f'Creating s3 resource object. {self.aws_account} {self.region} ')
            boto3_config = Config_boto3(connect_timeout=config.S3_CONNECTION_TIMEOUT, retries={'max_attempts': config.S3_MAX_ATTEMPTS})
            session = get_boto_session(self.aws_account, self.region)
            self._s3_resource = session.resource('s3', config=boto3_config)
        return self._s3_resource

    @property
    def s3_client(self):
        """obj`S3.Client`: S3 resource client"""

        return self.s3_resource.meta.client

    @property
    def s3_obj(self):
        """obj`S3.Object`: S3 file object"""

        if not self._s3_object:
            self._s3_object = self.s3_resource.Object(self.bucket, self.key)
        return self._s3_object

    @property
    def s3_obj_tags(self):
        """list: List of S3 file object tags"""

        if not self._s3_object_tags:
            self._s3_object_tags = self.s3_client.get_object_tagging(Bucket=self.bucket, Key=self.key)["TagSet"]
        return self._s3_object_tags

    @property
    def tags(self):
        """dict: S3 file object tags loaded into a python dict"""

        return {item['Key']: item['Value'] for item in self.s3_obj_tags}

    @property
    def local_filename(self):
        """str: full file path"""

        if not self._local_filename:
            base_dir = config.PATH_FILES_DL_LOCAL
            self._local_filename = os.path.join(base_dir, str(uuid4()) + Path(self.key).suffix)

        return self._local_filename

    @property
    def to_dict(self):
        """dict: data payload of this S3File object"""

        # Default variables to include in log messages
        return {
            'event_id': self.event_id,
            'account': self.aws_account,
            'bucket': self.bucket,
            'key': self.key,
        }

    def download(self):
        """Download file from S3 bucket into local filesystem

        Raises:
            err: Unable to download file from S3
        """

        logger.info('Downloading file from S3', extra=self.to_dict)
        start_time = time.time()
        try:
            self.s3_obj.download_file(self.local_filename)
            logs_extra = {
                'cmd': 'download',
                'size': self.size,
                'duration': round(time.time() - start_time)
            }
            logs_extra.update(self.to_dict)
            logger.info('File downloaded', extra=logs_extra)
        except Exception as err:
            logger.error(err)
            logger.error('Error downloading file from s3! Check Lambda IAM policy and make sure you have access to bucket.', extra=self.to_dict)
            raise err

    def set_tags(self, tags):
        """Set tags on S3 file object

        Args:
            tags (dict): dict of new tags
        Raises:
            Exception: unable to tag S3 object
        """

        new_tags = copy.copy(self.s3_obj_tags)

        for tag in self.s3_obj_tags:
            if tag['Key'] in tags.keys():
                new_tags.remove(tag)

        for k, v in tags.items():
            new_tags.append({'Key': k, 'Value': v})

        response = self.s3_client.put_object_tagging(Bucket=self.bucket, Key=self.key, Tagging={"TagSet": new_tags})
        if response['ResponseMetadata']['HTTPStatusCode'] != 200:
            log_extra = {
                'aws_error_msg': response['Error']['Message'],
                'http_code': response['ResponseMetadata']['HTTPStatusCode']
            }
            logging.error('tag_error', extra=log_extra)
            raise Exception('Error tagging s3 object. Return code is not 200')

        self._s3_object_tags = new_tags

    def cleanup(self):
        """Clean up downloaded S3 file from local filesystem"""

        if os.path.exists(self.local_filename):
            os.remove(self.local_filename)
            logger.info(f'Cached local file removed: {self.local_filename}', extra=self.to_dict)
        else:
            logger.info(f'Cached local file does not exits: {self.local_filename}')
