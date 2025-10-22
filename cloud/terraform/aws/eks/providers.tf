provider "aws" {
	default_tags {
		tags={
			DeploymentName=var.deployment_name
		}
	}
	region=var.region
}
provider "helm" {
	kubernetes={
		cluster_ca_certificate=module.eks.cluster_certificate_authority_data
		host=module.eks.cluster_endpoint
		token=data.aws_eks_cluster_auth.current.token
	}
}
provider "kubernetes" {
	cluster_ca_certificate=module.eks.cluster_certificate_authority_data
	host=module.eks.cluster_endpoint
	token=data.aws_eks_cluster_auth.current.token
}
terraform {
	required_providers {
		aws={
			source="hashicorp/aws"
			version="~> 6.14.1"
		}
		helm={
			source="hashicorp/helm"
			version="3.0.2"
		}
		kubernetes={
			source="hashicorp/kubernetes"
			version="~> 2.38.0"
		}
		random={
			source="hashicorp/random"
			version="~> 3.0"
		}
	}
	required_version=">=1.5.0"
}