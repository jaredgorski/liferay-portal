#!/bin/bash

echo "Executing run-on-boot.sh at $(date)"

TOKEN=$(      curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AMI_ID=$(     curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ami-id)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(     curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

echo "AMI ID: $AMI_ID"
echo "Instance ID: $INSTANCE_ID"
echo "Region: $REGION"
echo "AMI Profile: $(aws sts get-caller-identity)"

tree /opt/liferay

(
	cd /opt/liferay/terraform/eks

	if ! terraform show -json | jq -e '.values'
	then
		terraform init
		terraform apply -auto-approve \
			-var="deployment_name=lfr-ami-${INSTANCE_ID}" \
			-var="region=${REGION}"
		terraform output > ../dependencies/terraform.tfvars
	fi

	aws eks update-kubeconfig \
		--name $(terraform output -raw cluster_name) \
		--region $(terraform output -raw region)

	kubectl cluster-info
)