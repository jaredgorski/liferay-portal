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
		cluster_ca_certificate=base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
		host=module.eks.cluster_endpoint
		token=data.aws_eks_cluster_auth.current.token
	}
}
provider "kubernetes" {
	cluster_ca_certificate=base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
	host=module.eks.cluster_endpoint
	token=data.aws_eks_cluster_auth.current.token
}
terraform {
	required_providers {
		aws={
			source="hashicorp/aws"
			version="~> 6.18.0"
		}
		helm={
			source="hashicorp/helm"
			version="~> 3.0.2"
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