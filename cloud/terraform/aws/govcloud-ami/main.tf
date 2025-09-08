output "ami_id" {
    value=packer_image.this.manifest.builds[0].artifact_id
}
resource "packer_image" "this" {
    file="ami.pkr.hcl"
    force=true
    manifest_path="manifest.json"
    variables = {
        ami_name=var.ami_name
        ami_version=var.ami_version
        aws_region=var.aws_region
        instance_type=var.instance_type
    }
}