# Scanner lambda

Triggered via new messages pushed to a scan job SNS topic. Once triggered the scanner lambda will 
download the target S3 object described in the scan job message, scan the object and then tag it with the scan
results. It then sends an SNS message of the completed job for further processing
