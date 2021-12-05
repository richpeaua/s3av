# Dispatcher lambda

Monitors for Cloud Trail S3 object upload events and then dispatches a scan job to an SNS topic to then trigger the scanner lambda to scan the uploaded object
