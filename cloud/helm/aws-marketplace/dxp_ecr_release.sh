#!/usr/bin/env bash

export AWS_PROFILE=AWSAdministratorAccess-831926597587

DXP_TAG="${1?Argument specifying DXP image tag is required.}"
ECR_HOST=709825985650.dkr.ecr.us-east-1.amazonaws.com
ECR_REPOSITORY="liferay/containers5"
IMAGE_DESTINATION="${ECR_HOST}/${ECR_REPOSITORY}:${DXP_TAG}"
IMAGE_SOURCE="docker.io/liferay/dxp:${DXP_TAG}"

assert_lts() {
	if [[ "${DXP_TAG}" != *lts* ]]
	then
		echo "DXP tag is not LTS. Aborting."

		exit 1
	fi
}

assert_not_nightly() {
	if [[ "${DXP_TAG}" == *nightly* ]]
	then
		echo "DXP tag is nightly. Aborting."

		exit 1
	fi
}

assert_not_rc() {
	if [[ "${DXP_TAG}" == *rc* ]]
	then
		echo "DXP tag is release candidate. Aborting."

		exit 1
	fi
}

assert_slim() {
	if [[ "${DXP_TAG}" != *slim* ]]
	then
		echo "DXP tag is not slim. Aborting."

		exit 1
	fi
}

copy_dxp_image_to_ecr() {
	if ! command -v oras >/dev/null 2>&1
	then
		echo "Install `oras` CLI to continue: https://oras.land/docs/installation"

		exit 1
	fi

	if ! aws sso login
	then
		echo "Configure AWS SSO to access ${AWS_PROFILE} and retry."

		exit 1
	fi

	aws ecr get-login-password --region us-east-1 | oras login "${ECR_HOST}" \
		--password-stdin \
		--username AWS

	oras cp "${IMAGE_SOURCE}" "${IMAGE_DESTINATION}"
}

copy_dxp_image_to_ecr_with_retry() {
	for i in 1 2 3 4 5
	do
		copy_dxp_image_to_ecr && break

		if [[ "${i}" -lt 5 ]]
		then
			echo "Try ${i} failed. Retry in 15 seconds."

			sleep 15
		else
			echo "Try ${i} failed. Out of retries."

			exit 1
		fi
	done
}

main() {
	echo "Using DXP Image Tag: ${DXP_TAG}"

	assert_lts

	assert_not_nightly

	assert_not_rc

	assert_slim

	copy_dxp_image_to_ecr_with_retry
}

main