#!/usr/bin/env bash

export AWS_PROFILE=AWSAdministratorAccess-831926597587

CHART_NAME=$(cat ./Chart.yaml | yq .name)
CHART_VERSION=$(cat ./Chart.yaml | yq .version)
ECR_HOST=709825985650.dkr.ecr.us-east-1.amazonaws.com
ECR_REPOSITORY="liferay/charts5"
PACKAGED_CHART_FILENAME="${CHART_NAME}-${CHART_VERSION}.tgz"
RELEASE_DESTINATION="${ECR_HOST}/${ECR_REPOSITORY}"

cleanup() {
	rm -rf ${PACKAGED_CHART_FILENAME} Chart.lock charts
}

configure_aws_ecr() {
	aws sso login

	aws ecr get-login-password --region us-east-1 | \
		helm registry login --password-stdin --username AWS ${ECR_HOST}
}

push_chart_to_ecr() {
	if ! command -v oras >/dev/null 2>&1
	then
		echo "Install `oras` CLI to continue: https://oras.land/docs/installation"

		exit 1
	fi

	helm dependency update

	helm package .

	oras push "${RELEASE_DESTINATION}" "${PACKAGED_CHART_FILENAME}"

	echo "Contents of ECR repository ${ECR_REPOSITORY}:"

	aws --no-cli-pager ecr describe-images --region us-east-1 --registry-id "${ECR_HOST:0:12}" --repository-name "${ECR_REPOSITORY}"
}

main() {
	echo "Publishing AWS Marketplace Helm chart to registry: ${ECR_HOST}"
	echo "Publishing AWS Marketplace Helm chart to repository: ${ECR_REPOSITORY}"
	echo "Publishing AWS Marketplace Helm chart with name: ${CHART_NAME}"
	echo "Publishing AWS Marketplace Helm chart with version: ${CHART_VERSION}"

	trap cleanup EXIT

	configure_aws_ecr

	push_chart_to_ecr
}

main