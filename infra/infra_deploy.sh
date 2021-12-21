#!/bin/bash
#
# Deploy the infra in the correct order to avoid missing dependency conflicts

set -euo pipefail
GROUP_ONE_RESOURCES=("module.appconfig" "module.kms" "aws_secretsmanager_secret.s3av" "module.ecr_scanner" "module.ecr_notifier" "aws_sns_topic.scan" "aws_sns_topic.notification")
# GROUP_ONE_RESOURCES=("module.vpc" "aws_security_group.lambda_scanner" "module.appconfig" "module.kms" "aws_secretsmanager_secret.s3av" "module.ecr_scanner" "module.ecr_notifier" "aws_sns_topic.scan" "aws_sns_topic.notification")
GROUP_TWO_RESOURCES=("module.lambda_scanner" "module.lambda_notifier" "module.s3_event" "aws_cloudwatch_event_target.update_vs_db" "aws_sns_topic_subscription.notify_sns_to_notifier_lambda" "aws_sns_topic_subscription.scan_sns_to_scanner_lambda")
LAMBDA_RESOURCES=("module.lambda_scanner" "module.lambda_notifier")
PROJECT_DIR=$(pwd)/terraform

function tf_target_run() {
    target_op=$1
    target_res=$2

    terraform $target_op -target="$target_res" -auto-approve
}

function deploy_new_lambda_image() {
    terraform apply -target="module.lambda_scanner" -auto-approve 
}

function group_operation() {
    group=$1
    operation=$2

    case $group in
        one) target_group="${GROUP_ONE_RESOURCES[@]}" ;;
        two) target_group="${GROUP_TWO_RESOURCES[@]}" ;;
        *) echo "group doesn't exist"; exit 1 ;;
    esac

    case $operation in
        apply) resources=$target_group ;;
        destroy) resources=$(printf '%s\n' $target_group | tac | tr '\n' ' '; echo) ;;
        *) echo "operation doesn't exist"; exit 1 ;;
    esac

    for resource in $resources
    do
        tf_target_run $operation $resource
    done
}

function main () {
    group=$1
    operation=$2

    cd $PROJECT_DIR

    group_operation $group $operation
}

main "$@"