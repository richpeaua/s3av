#!/bin/bash

# Deploy the infra in the correct order to avoid missing dependency conflicts

function tf_target_apply() {
    terraform apply -target="$1" -auto-approve
}

function tf_target_destroy() {
    terraform destroy -target="$1" -auto-approve
}

function deploy_scannable_buckets() {
    terraform apply -target="module.s3_bucket" -auto-approve 
}

function deploy_one() {
    deploy_one_resources=("vpc" "appconfig" "kms" "asm")

    terraform apply -target="module.vpc"
    terraform apply -target="aws_security_group.lambda_scanner" -auto-approve
    terraform apply -target="module.appconfig"
    terraform apply -target="module.kms"
    terraform apply -target="aws_secretsmanager_secret.s3av" -auto-approve
    terraform apply -target="module.ecr_scanner"
    terraform apply -target="module.ecr_notifier" -auto-approve
    terraform apply -target="aws_sns_topic.scan" -auto-approve
    terraform apply -target="aws_sns_topic.notification" -auto-approve
}

function deploy_two() {
    terraform apply -target="module.lambda_scanner" -auto-approve
    terraform apply -target="module.lambda_notifier" -auto-approve
    terraform apply -target="module.s3_event" -auto-approve
    terraform apply -target="aws_cloudwatch_event_target.update_vs_db" -auto-approve
    terraform apply -target="aws_sns_topic_subscription.notify_sns_to_notifier_lambda" -auto-approve
    terraform apply -target="aws_sns_topic_subscription.scan_sns_to_scanner_lambda" -auto-approve

}
