import os
import os.path
import json
import time
import logging
import subprocess
import traceback
from glob import glob

from botocore.client import Config as boto_config

from common import timestamp_now, get_boto_session, get_appconfig
from configs import config
from s3 import S3File
from notify import get_sns_topics

logger = logging.getLogger()

STATUS_INFECTED = 'INFECTED'
STATUS_CLEAN = 'CLEAN'

class ScanFilterConfig(object):
    """Configuration of scannable S3 buckets and the AWS accounts the bucket resides in

    Used to provide a filter by which to determine if a target S3 file object is scannable or not

    Args:
        config (dict): a python dict loaded from a json formatted config file
    """

    def __init__(self, config) -> None:
        super().__init__()
        self.config = config

    def is_match(self, account_id, bucket):
        """Checks whether an AWS account or S3 bucket name exist within the 'scan_scope' config

        Args:
            account_id (str): AWS account id
            bucket (str): S3 Bucket name
        Returns:
            bool: True if the AWS account AND S3 bucket exist in the configs file, else False
        """
        
        scope = self.config['scan_scope']
        bucket_scope = scope['enabled_accounts'][account_id]['buckets']

        if bucket not in bucket_scope:
            # Empty account in configs means all accounts
            logger.info(f'AWS S3 Bucket not in scope: {bucket}.')
            return False

        return True


class ScanResult(object):
    """ScanResult object for parsing virus scan results

    This object merges S3File object data with virus scan results. Includes functionality to return
    the updated merged data for further processing according to the added post-scan results.

    Args:
        cli_stdout (str): string (utf-8 encoded) formatted stdout returned from clamscan command run via subprocess.run() function.
        s3_obj (:obj:`S3File`): S3 file object that has been scanned
    """

    def __init__(self, cli_stdout, s3_obj) -> None:
        super().__init__()
        self._results = {}
        self.s3_obj = s3_obj
        self.load_from_cli_stdout(cli_stdout)
        self.timestap = timestamp_now()

    def load_from_cli_stdout(self, cli_stdout):
        """Parses the cli_stdout string for keys/values and loads them into a dict

        Args:
            cli_stdout (str): string (utf-8 encoded) formatted stdout returned from clamscan command run via subprocess.run() function.
        """

        for line in cli_stdout.split('\n'):
            if ':' in line:
                k, v = line.split(':', 1)
                self._results[k] = v.strip()

    @property
    def signature(self):
        """Return `str` of the signature/s of discovered virus/es"""

        return self._results.get(self.s3_obj.local_filename, 'UNKNOWN').replace('FOUND', '').strip()

    @property
    def duration(self):
        """Return `float` of virus scan duration"""

        return round(float(self._results['Time'].split(' ')[0]))

    @property
    def known_viruses(self):
        """Return `int` number of viruses found post-scan"""

        return int(self._results['Known viruses'])

    @property
    def is_infected(self):
        """Return `bool` indicating whether scanned file is infected or not"""

        return self._results['Infected files'] != '0'

    @property
    def status(self):
        """Return `str` of the files virus-scan status"""

        if self.is_infected:
            return STATUS_INFECTED
        return STATUS_CLEAN

    @property
    def to_dict(self):
        """Return `dict` of merged S3File object data and scan results"""

        obj_dict = self.s3_obj.to_dict
        obj_dict.update(
            {
                'status': self.status,
                'signature': self.signature,
            }
        )
        return obj_dict


class S3VirusScanner(object):
    """S3VirusScanner scans an s3 file for viruses

    This object encapsulates ClamAV functionality to perform virus scans on a target s3 file object.
    """

    def __init__(self) -> None:
        super().__init__()
        self.create_data_dir()

        self._s3_file = None
        self._scan_results = None

    def create_data_dir(self):
        """Creates the data directory where ClamAV virus definition db and files to-be-scanned are stored

        Raises:
            OSError: If unable to create ClamAv data dir
        """

        if not os.path.exists(config.VS_PATH_DB):
            try:
                logger.info(f'Create directory {config.VS_PATH_DB}')
                os.makedirs(config.VS_PATH_DB)
            except OSError as exc:
                logger.error(f'Error while creating ClamAV data dir {config.VS_PATH_DB}')
                raise

    def update_db(self):
        """Pulls down latest ClamAV virus database

        Raises:
            Exception: If unable to pull ClamAV database updates
        Returns:
            int: Return code of completed ClamAV db update command
        """

        # Update ClamAV Database with freshclam
        logger.info(f'Downloading ClamAV database files to: {config.VS_PATH_DB}')
        cmd = ['freshclam', f'--config-file={config.VS_PATH_FRESHCLAM_CONF}', f'--user={config.VS_USER}', f'--datadir={config.VS_PATH_DB}']
        proc = subprocess.run(cmd, encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=os.environ.copy(), shell=False)

        if proc.returncode != 0:
            logger.error('Error while updating ClamAV database')
            logger.error(proc.args)
            logger.error(proc.stdout)
            raise Exception(proc.stdout)

        logs_extra = {'cmd': 'vs_db_update'}
        logger.info('db_updated', extra=logs_extra)
        logger.info(proc.stdout)
        return proc.returncode

    def download_db_if_not_exists(self):
        """Check if ClamAV database exists

        Raises:
            Exception: If ClamAV database files are missing
        """

        # There are 'usually' three database files downloaded from the default mirror that have extensions '.cvd' [see https://blog.clamav.net/2021/03/clamav-cvds-cdiffs-and-magic-behind.html]
        #   1. daily.cvd - latest threats signatures
        #   2. main.cvd - signatures previously in 'daily.cvd' filtered for low false-positives
        #   3. bytecode.cvd - contains all compiled bytecode signatures
        # If a Clamav DB update occurs, the '.cvd' files are uncompressed, updated and remain in the uncompressed '.cld' format.
        # Both formats are valid to perform scan, which is why we check if the three exist with either '.cvd' or '.cld' extensions.
        if len(glob(os.path.join(config.VS_PATH_DB, '*.c[lv]d'))) < 3:
            logger.info(f'Database files are missing in {config.VS_PATH_DB}')
            os.system(f'ls -lh {config.VS_PATH_DB}')
            self.update_db()
            time.sleep(1)
            if len(glob(os.path.join(config.VS_PATH_DB, '*.c[lv]d'))) < 3:
                os.system(f'ls -lh {config.VS_PATH_DB}')
                raise Exception('Virus scan database files are missing!')


    def load_from_event_data(self, event):
        """Pulls the target s3 file object to scan from an SNS message and then instantiates
        an S3File object mapped to target file object for further scanning and processing

        Args:
            event (json): SNS message event payload [see https://docs.aws.amazon.com/lambda/latest/dg/with-sns.html]
        """

        # We should have only 1 record inside S3 event
        assert len(event['Records']) == 1

        assert event['Records'][0]['EventSource'] == 'aws:s3'

        sns_msg = json.loads(event['Records'][0]['Sns']['Message'])

        self._s3_file = S3File(sns_msg)

    def should_scan(self):
        """Checks whether bucket name/owning AWS account in SNS event message are in scanning scope, according to buckets/accounts ennumerated in app configs.

        Returns:
            boolean: True if bucket/target file are within scanning scope, as enumerated in scan_config.json config file, else False
        """

        app_config = get_appconfig()
        scan_config = ScanFilterConfig(app_config)

        return scan_config.is_match(self._s3_file.aws_account, self._s3_file.bucket)

    def scan(self):
        """Runs clamscan virus scan on downloaded S3 file and then returns scan results.

        Raises:
            Exception: If clamscan command fails. Output of clamscan error included in exception.
        Returns:
            ScanResult: ScanResult object containing data from virus scan.
        """

        logger.info(f'Scanning file: {self._s3_file.local_filename}', extra=self._s3_file.to_dict)

        self._s3_file.download()

        cmd = ['clamscan', '-v', '-a', f'--database={config.VS_PATH_DB}', self._s3_file.local_filename]
        proc = subprocess.run(cmd, encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=os.environ.copy(), shell=False)

        if proc.returncode not in (0, 1):
            logger.error('Error while scanning file')
            logger.error(proc.args)
            logger.error(proc.stdout)
            raise Exception(proc.stdout)

        results = ScanResult(proc.stdout, self._s3_file)

        logs_extra = {
            'cmd': 'scan',
            'size': self._s3_file.size,
            'duration': results.duration,
            'status': results.status,
            'known_viruses': results.known_viruses
        }
        if results.is_infected:
            logs_extra['signature'] = results.signature

        logs_extra.update(self._s3_file.to_dict)
        logger.info('S3 object scanned', extra=logs_extra)

        if proc.returncode == 0:
            # The 0 return code means no finding
            assert results.is_infected == False
        else:
            # If return code is 1, we should have a findig
            assert results.is_infected == True

        self._scan_results = results
        return self._scan_results

    def set_scan_tags(self):
        """Set tags on scanned S3 file indicating scan results"""

        tags = {
            config.VS_S3_OBJ_TAG_STATUS: self._scan_results.status,
            config.VS_S3_OBJ_TAG_SIGNATURE: self._scan_results.signature,
            config.VS_S3_OBJ_TAG_TIMESTAMP: self._scan_results.timestap
        }

        self._s3_file.set_tags(tags)

        logs_extra = {'cmd': 'tag'}
        logs_extra.update(tags)
        logs_extra.update(self._s3_file.to_dict)
        logger.info(f'S3 object tagged', extra=logs_extra)

    def notify(self):
        """Publish SNS event notifying a completed file scan

        Raises:
            err: Unable to publish scan completion event to SNS. Could be connection problem or topic does not exist
            Exception: Unable to publish to SNS. HTTP return code is not 200.
        """

        boto3_config = boto_config(connect_timeout=config.SNS_CONN_TIMEOUT, retries={'max_attempts': config.SNS_CONN_MAX_ATTEMP})

        scan_results = self._scan_results.to_dict
        sns_topics = get_sns_topics(scan_results)

        if not sns_topics:
            return

        for sns_arn in sns_topics:
            logging.debug('Publishing to SNS', extra=scan_results)
            logs_extra = {'event_id': scan_results["event_id"], 'sns_arn': sns_arn}

            sns_aws_region_name = sns_arn.split(':')[3]
            sns_aws_account_id = sns_arn.split(':')[4]
            session = get_boto_session(sns_aws_account_id, sns_aws_region_name)
            sns = session.client('sns', config=boto3_config)

            try:
                response = sns.publish(TopicArn=sns_arn, Message=json.dumps(scan_results), Subject='Notify', MessageStructure='string')
            except Exception as err:
                logging.error('publish_sns_error', extra=logs_extra)
                logging.error(traceback.format_exc())
                raise err
            else:
                if response['ResponseMetadata']['HTTPStatusCode'] != 200:
                    logs_extra.update({'http_code': response['ResponseMetadata']['HTTPStatusCode']})
                    logging.error('publish_sns_error', extra=logs_extra)
                    raise Exception('Error publishing to SNS. Return code is not 200')
                logging.debug('published_sns', extra=logs_extra)

        scan_results.update({'cmd': 'notify', 'sns_topics': sns_topics})
        logger.info('Published to SNS topics', extra=scan_results)

    def cleanup(self):
        """Clean up downloaded and scanned S3 file on the attached EFS in preparation for next scan"""

        self._s3_file.cleanup()
