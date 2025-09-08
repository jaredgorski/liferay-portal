## Configure Credentials for AWS CLI

1. Install AWS CLI

   ```shell
   # Install AWS CLI
   curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. Setup login credentials

   ```shell
   aws configure --profile PROFILE_NAME
   ```

3. Export the profile as default

   ```shell
   export AWS_PROFILE=PROFILE_NAME
   ```

## Use Hashicorp Packer to build EC2 AMI Image

1. Install packer:

   ```shell
   brew tap hashicorp/tap
   brew install hashicorp/tap/packer
   ```

2. Init packer:

   ```shell
   packer init .
   ```

3. Build the AMI using packer:

   ```shell
   packer build .
   ```

### Build with Terraform

1. Install Terraform

   ```shell
   brew install terraform
   ```

2. Init Terraform:

   ```shell
   terraform init
   ```

3. Execute the Terraform:

   ```shell
   terraform apply
   ```
