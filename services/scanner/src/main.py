import logging
import traceback

from logger import setup_logger
from scanner import S3VirusScanner

def update():
    vs = S3VirusScanner()
    vs.update_db()


def scan(event):
    vs = S3VirusScanner()
    vs.load_from_event_data(event)

    if not vs.should_scan():
        logging.info(f'AWS bucket is not in scope. Stopping ...')
        return

    vs.download_db_if_not_exists()

    try:
        vs.scan()
        vs.set_scan_tags()
        vs.notify()
    except Exception as err:
        vs.cleanup()
        raise err


def main(event):
    if event.get('command', None) == 'update':
        logging.info('Update command received! Updating ...')
        update()
    else:
        scan(event)


def lambda_handler(event, context):
    setup_logger(aws_request_id=context.aws_request_id)

    logger = logging.getLogger()

    try:
        main(event)
        return 'done'
    except Exception as err:
        logger.error('Error while scanning!')
        logger.error(repr(event))
        logger.error(traceback.format_exc())
        raise err
