#!/bin/bash -eux

# Install dependencies
sudo yum update --assumeyes
sudo yum install --assumeyes git jq tree shadow-utils unzip yum-utils

# Install AWS CLI
curl --fail-with-body --location --show-error --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" --output "awscliv2.zip"
unzip awscliv2.zip -x "aws/dist/awscli/examples/*"
sudo ./aws/install
rm awscliv2.zip

# Install Terraform
TERRAFORM_VERSION="1.13.1"
curl --fail-with-body --location --show-error --silent "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" --output "terraform.zip"
unzip terraform.zip
sudo mv terraform /usr/local/bin/
rm terraform.zip

# Install Kubernetes Client
KUBERNETES_VERSION="1.23.6"
curl --fail-with-body --location --show-error --silent "https://dl.k8s.io/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl" --output "kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install eksctl
curl --fail-with-body --location --show-error --silent "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" --output "eksctl.tar.gz"
tar xz -f eksctl.tar.gz
sudo mv eksctl /usr/local/bin
rm eksctl.tar.gz

# Install Helm
curl --fail-with-body --location --show-error --silent https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 --output "get_helm.sh"
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

# Setup Liferay Cloud Native
CHART_DIR=/opt/liferay/awsmp-chart
TERRAFORM_DIR=/opt/liferay/terraform

sudo mkdir --parents "${TERRAFORM_DIR}"
sudo mkdir --parents "${CHART_DIR}"

sudo chown --recursive 1000:1000 /opt/liferay

# Install Liferay Cloud Native
CHART_VERSION=0.0.5-20250429134228
ECR_HOST=709825985650.dkr.ecr.us-east-1.amazonaws.com
OCI_ENDPOINT="oci://${ECR_HOST}/liferay/charts"

export HELM_EXPERIMENTAL_OCI=1

aws ecr get-login-password --region us-east-1 | helm registry login "${ECR_HOST}" \
	--username AWS \
	--password-stdin

cd "${CHART_DIR}"

helm pull "${OCI_ENDPOINT}" --version "${CHART_VERSION}"

tar xf "$(pwd)/*" && find "$(pwd)" -maxdepth 1 -type f -delete

helm install liferay ./* \
	--create-namespace \
	--namespace liferay-system