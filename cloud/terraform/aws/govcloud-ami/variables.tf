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