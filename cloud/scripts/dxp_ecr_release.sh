#!/usr/bin/env bash

export AWS_PROFILE="${1:-AWSAdministratorAccess-831926597587}"

DOCKER_TAGS_REQUEST_PAGES=10
DOCKER_TAGS_REQUEST_PAGE_SIZE=100

DXP_SOURCE_REGISTRY="docker.io"
DXP_SOURCE_REPOSITORY="liferay/dxp"

ECR_REGION="us-east-1"
ECR_REGISTRY_ID="709825985650"

ECR_HOST="${ECR_REGISTRY_ID}.dkr.ecr.${ECR_REGION}.amazonaws.com"
ECR_IMAGE_NAME="dxp"
ECR_REGISTRY="${ECR_HOST}/liferay"
ECR_REPOSITORY_NAME="liferay/${ECR_IMAGE_NAME}"

docker_pull_and_tag() {
	local tag=${1}
	local source="${DXP_SOURCE_REGISTRY}/${DXP_SOURCE_REPOSITORY}:${tag}"
	local destination="${ECR_REGISTRY}/${ECR_IMAGE_NAME}:${tag}"

	docker pull "${source}"

	docker tag "${source}" "${destination}"
}

docker_push_to_ecr() {
	local tag=${1}
	local source="${DXP_SOURCE_REGISTRY}/${DXP_SOURCE_REPOSITORY}:${tag}"
	local destination="${ECR_REGISTRY}/${ECR_IMAGE_NAME}:${tag}"

	ensure_ecr_auth

	docker push "${destination}"

	docker rmi "${source}" "${destination}"
}

ensure_ecr_auth() {
    if ! aws sts get-caller-identity --profile "${AWS_PROFILE}" >/dev/null 2>&1
	then
		aws sso login --profile "${AWS_PROFILE}" || {
			echo "Configure AWS SSO to access ${AWS_PROFILE} and retry."

			exit 1
		}
    fi

	aws ecr get-login-password --region us-east-1 | docker login "${ECR_HOST}" \
		--password-stdin \
		--username AWS >/dev/null 2>&1
}

fetch_promoted_release_tags() {
	local promoted_release_tags
	promoted_release_tags=$(curl -s "https://releases.liferay.com/releases.json" | jq -c '[.[] | select(.promoted == "true" and .product == "dxp") | .releaseKey | ltrimstr("dxp-")]')

	local docker_tags
	docker_tags=$(
		for i in $(seq 1 $DOCKER_TAGS_REQUEST_PAGES)
		do
			local response
			response=$(curl -s "https://hub.docker.com/v2/repositories/${DXP_SOURCE_REPOSITORY}/tags/?page=${i}&page_size=${DOCKER_TAGS_REQUEST_PAGE_SIZE}")

			if [[ $(echo "${response}" | jq '.results | length') -eq 0 ]]
			then
				break
			fi

			echo "${response}" | jq -c '.results[].name'
		done | jq -s -c 'unique'
	)

	echo "${docker_tags}" | jq --argjson promoted "${promoted_release_tags}" -r '
		.[] | . as $name |
		select(
			($name | contains("-d")) and
			($name | contains("lts")) and 
			($name | contains("nightly") | not) and 
			($name | contains("rc") | not) and
			($name | contains("slim")) and
			(any($promoted[]; $name | startswith(.)))
		)'
}

should_sync_tag() {
	local tag=${1}

	if aws ecr describe-images \
		--image-ids imageTag="${tag}" \
		--profile "${AWS_PROFILE}" \
		--region us-east-1 \
		--registry-id 709825985650 \
		--repository-name "${ECR_REPOSITORY_NAME}" >/dev/null 2>&1
	then
		return 1
	fi

	return 0
}

sync_tag() {
	local tag=${1}

	should_sync_tag "${tag}" || {
		echo "Skipping: ${tag} (already exists)"

		return 0
	}

	echo "Syncing: ${tag}"

	with_retry docker_pull_and_tag "${tag}" || return 1

	with_retry docker_push_to_ecr "${tag}" || return 1

	echo "Synced: ${tag}"
}

with_retry() {
	local func=${1}
	local arg=${2}

	for i in 1 2 3 4 5
	do
		$func "${arg}" && return 0

		if [[ "${i}" -lt 5 ]]
		then
			echo "Try ${i} failed. Retry in 15 seconds."

			sleep 15
		else
			echo "Try ${i} failed. Out of retries."

			return 1
		fi
	done
}

main() {
	local tags_to_sync
	tags_to_sync=$(fetch_promoted_release_tags)

	for tag in $tags_to_sync; do
		sync_tag "${tag}" || echo "Failed sync: ${tag}. Continuing."
	done

	echo "Done."
}

main