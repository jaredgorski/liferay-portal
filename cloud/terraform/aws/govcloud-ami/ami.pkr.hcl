build {
    name="liferay-ami-govcloud-builder"
    post-processor "manifest" {
        output="manifest.json"
        strip_path=true
    }

    # provisioner order must be maintained
    provisioner "shell" {
        script="install_tools.sh"
    }
    provisioner "file" {
        source      = "../"
        destination = "/opt/liferay/terraform"
    }
    provisioner "file" {
        source      = "run-on-boot.sh"
        destination = "/tmp/run-on-boot.sh"
    }
    provisioner "file" {
        source      = "run-on-boot.cfg"
        destination = "/tmp/run-on-boot.cfg"
    }
    provisioner "shell" {
        inline = [
            "sudo mv /tmp/run-on-boot.sh /usr/local/bin/run-on-boot.sh",
            "sudo mv /tmp/run-on-boot.cfg /etc/cloud/cloud.cfg.d/99-run-on-boot.cfg"
        ]
    }

    sources=[
        "source.amazon-ebs.this"
    ]
}
packer {
    required_plugins {
        amazon={
            source="github.com/hashicorp/amazon"
            version=">= 1.4.0"
        }
    }
}
source "amazon-ebs" "this" {
    ami_name="${var.ami_name}-${var.ami_version}"
    instance_type=var.instance_type
    region=var.aws_region
    source_ami_filter {
        filters={
            name="amzn2-ami-hvm-*-x86_64-gp2"
            root-device-type="ebs"
            virtualization-type="hvm"
        }
        owners=[
            "amazon"
        ]
        most_recent=true
    }
    ssh_username="ec2-user"
    ssh_clear_authorized_keys=true
}
variable "ami_name" {
    default="liferay-ami-govcloud-bootstrap"
}
variable "ami_version" {
    default="v1"
}
variable "aws_region" {
    type=string
}
variable "instance_type" {
    default="t3.micro"
}