#!/usr/bin/env bash

PRODUCT_VERSION="${1?Argument specifying new AWS Marketplace product version is required.}"

DETAILS_JSON='{
	"DeliveryOptions": [
		{
			"Details": {
				"ContainerProductDeliveryOptionDetails": {
					"ContainerImages": [
						{
							"ImageDigest": "sha256:abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
							"ImageTag": "latest"
						}
					],
					"DeliveryOptionTitle": "Deploy using Helm and Terraform",
					"DeliveryOptionType": "Public",
					"Description": "This option supports deployment of Liferay using Helm and Terraform.\n\nService Dependencies\n\nThere are 3 service dependencies which are instantiated using Terraform scripts; an RDS Postgres database, an OpenSearch domain and an S3 bucket.\n\nThese are created within the AWS account executing the Terraform scripts and are fully under control of the account owner.",
					"EcrRepositoryArn": "arn:aws:ecr:us-east-1:123456789012:repository/my-ecr-repo",
					"EcrRepositoryName": "liferay/charts",
					"HelmInstallationNamespace": "liferay-system",
					"HelmReleaseName": "liferay",
					"KubernetesServiceAccountName": "liferay-default",
					"SupportedRegions": [
						"us-east-1",
						"us-west-2"
					],
					"SupportedServices": [
						"Amazon Elastic Kubernetes Service (EKS)"
					]
				}
			},
			"Type": "ContainerProductDeliveryOption@1.0"
		}
	],
	"Version": {
		"ReleaseNotes": "My new Release notes",
		"VersionTitle": "'${PRODUCT_VERSION}'"
	}
}'
ENTITY_ID="prod-7xd5pjyie6zee"
ENTITY_TYPE="ContainerProduct@1.0"

CHANGE_SET_JSON='[
	{
		"ChangeType": "AddDeliveryOptions",
		"Details": '"${DETAILS_JSON}"',
		"Entity": {
			"Identifier": "'${ENTITY_ID}'",
			"Type": "'${ENTITY_TYPE}'"
		}
	}
]'
CHANGE_SET_JSON_STRING=$(echo "${CHANGE_SET_JSON}" | jq 'tostring')

configure_aws() {
	aws sso login
}

start_change_set() {
	aws marketplate-catalog start-change-set \
		--catalog "AWSMarketplace" \
		--change-set "${CHANGE_SET_JSON_STRING}"
}

main() {
	echo "Using product version: ${PRODUCT_VERSION}"

	configure_aws

	start_change_set
}

main