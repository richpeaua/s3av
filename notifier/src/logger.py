import logging
from pythonjsonlogger import jsonlogger


class CustomJsonFormatter(jsonlogger.JsonFormatter):
    def __init__(self, *args, **kwargs):
        self.aws_request_id = kwargs.pop('aws_request_id')
        super().__init__(*args, **kwargs)

    def add_fields(self, log_record, record, message_dict):
        super(CustomJsonFormatter, self).add_fields(log_record, record, message_dict)

        log_record['aws_request_id'] = self.aws_request_id

        if log_record.get('level'):
            log_record['level'] = log_record['level'].upper()
        else:
            log_record['level'] = record.levelname


def setup_logger(log_level=logging.INFO, **kwargs):
    logger = logging.getLogger()

    # AWS Lambda sets up one default handler.
    # We should have only 1 handler when app starts
    assert len(logger.handlers) == 1

    logger.setLevel(log_level)
    logHandler = logging.StreamHandler()

    formatter = CustomJsonFormatter(
        fmt='%(level)s %(message)s %(aws_request_id)s',
        **kwargs
    )

    logHandler.setFormatter(formatter)
    logger.addHandler(logHandler)

    # We are removing AWS Lambda default handler
    logger.removeHandler(logger.handlers[0])
