from common import read_service_config
from configs import config


class SNSConfig(object):
    
    def __init__(self, sns_config) -> None:
        super().__init__()
        self.sns_config = sns_config

    def is_match(self, results):
        if self.sns_config['accounts'] and results['account'] not in self.sns_config['accounts']:
            # Empty account in configs means all accounts
            return False

        if self.sns_config['buckets'] and results['bucket'] not in self.sns_config['buckets']:
            # Empty account in configs means all accounts
            return False

        if (self.sns_config['finding'] == 'ALL') or (self.sns_config['finding'] == results['status']):
            return True

        return False


def get_sns_configs():
    srvc_config = read_service_config(config.PATH_SRVC_CONFIG)
    notify_config = srvc_config['results_sns_routes']
    for sns_raw_config in notify_config:
        yield SNSConfig(sns_raw_config)


def get_sns_topics(results):
    return [i.sns_config['dest_sns_arn'] for i in get_sns_configs() if i.is_match(results)]
