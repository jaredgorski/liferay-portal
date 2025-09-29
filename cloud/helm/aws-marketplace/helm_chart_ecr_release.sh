#!/usr/bin/env bash

export AWS_PROFILE=AWSAdministratorAccess-831926597587
export HELM_EXPERIMENTAL_OCI=1

CHART_NAME=$(cat ./Chart.yaml | yq .name)
CHART_VERSION=$(cat ./Chart.yaml | yq .version)
ECR_HOST=709825985650.dkr.ecr.us-east-1.amazonaws.com
ECR_REPOSITORY="liferay/charts"
PACKAGED_CHART_FILENAME="${CHART_NAME}-${CHART_VERSION}.tgz"
RELEASE_DESTINATION="${ECR_HOST}/${ECR_REPOSITORY}:${CHART_VERSION}"

cleanup() {
	rm -rf ${PACKAGED_CHART_FILENAME} Chart.lock charts
}

configure_aws_ecr() {
	aws sso login

	aws ecr get-login-password --region us-east-1 | \
		helm registry login --password-stdin --username AWS ${ECR_HOST}
}

push_chart_to_ecr() {
	helm dependency update

	helm package . --version "${CHART_VERSION}"

	helm push "${PACKAGED_CHART_FILENAME}" "oci://${RELEASE_DESTINATION}"

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