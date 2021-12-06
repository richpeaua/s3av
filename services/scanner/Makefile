# For multiple .env files in format '.env.ENV', for example '.env.prod' or '.env.sandbox'
ENV ?=
ifdef ENV
	TARGET_ENV_FILE := .env.${ENV}
	ifneq (,$(wildcard ./${TARGET_ENV_FILE}))
		include ${TARGET_ENV_FILE}
		export
	else
$(warning The env file `${TARGET_ENV_FILE}` does not exist.)
	endif
else
# if ENV not provided then default to plain '.env'
	ifneq (,$(wildcard ./.env))
		include .env
		export
	else
$(warning Missing a `.env` file, see `.env.example` OR set `ENV` variable for specific `.env.ENV` file, if exists, e.g. `make env-verify ENV=sandbox`)
	endif
endif

export AWS_PROFILE
export AWS_REGION
export AWS_DEFAULT_REGION := ${AWS_REGION}

IMAGE_URL := ${ECR_REPO}${ECR_IMAGE_PATH}
IMAGE_TAG_RANDOM := $(shell git rev-parse --short HEAD)-$(shell bash -c 'echo $$RANDOM')
IMAGE_TAG ?= ${IMAGE_TAG_RANDOM}
IMAGE := ${IMAGE_URL}:${IMAGE_TAG}
IMAGE_LATEST := ${IMAGE_URL}:latest

TEST_EVENTS_DIR := tests/events
EVENT ?= s3_put_1.json
TEST_EVENT_DATA := $(shell cat ${TEST_EVENTS_DIR}/${EVENT})

.PHONY: help
help: ## Print this help
help:
	@echo 'Usage: make <target>'
	@echo
	@echo -e 'Targets:'
	@egrep '^(.+)\:\ ##\ (.+)' $(MAKEFILE_LIST) | column -t -c 2 -s ':#'

.PHONY: echo
echo: ## Print included vars from `.env` OR `.env.ENV` files
	@echo "Included vars:"
	@echo "DEPLOY_ENV = ${DEPLOY_ENV}"
	@echo "AWS_PROFILE = ${AWS_PROFILE}"
	@echo "AWS_REGION = ${AWS_REGION}"
	@echo "AWS_DEFAULT_REGION = ${AWS_DEFAULT_REGION}"
	@echo "ECR_REPO = ${ECR_REPO}"
	@echo "APPCONFIG_EXT_ARN = ${APPCONFIG_EXT_ARN}"

.PHONY: env-verify
env-verify: echo ## Verify the build/deploy environment
	@echo "Target deployment env is: ${DEPLOY_ENV}"
	@echo "is this correct? [y/N]" && read ans && [ $${ans:-N} = y ]

.PHONY: ecr-login
ecr-login: ## Login into AWS ECR
	aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REPO}

.PHONY: lock ## Lock pipenv enviroument and create requirements.txt files
lock: 
	pipenv lock
	pipenv lock -r > requirements.txt

.PHONY: build
build: env-verify ecr-login ## Build docker image
	@stat build_resources || mkdir build_resources
	@stat build_resources/layer.zip || curl "$(shell aws --profile ${AWS_PROFILE} --region ${AWS_DEFAULT_REGION} lambda get-layer-version-by-arn --arn ${APPCONFIG_EXT_ARN} --query 'Content.Location' --output text)" --output build_resources/layer.zip
	docker build --no-cache --rm --force-rm -t ${IMAGE} .
	docker tag ${IMAGE} ${IMAGE_LATEST}

.PHONY: push
push: ## Push docker image
	docker push ${IMAGE}

.PHONY: deploy
deploy: build push clean ## Deploy docker image

.PHONY: clean
clean: ## clean up mess from sandbox build
	rm -rf build_resources
