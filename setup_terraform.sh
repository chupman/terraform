#!/bin/bash

echo "Creating the Terraform plugins directory in ~/.terraform.d/plugins/ so Terraform can find the IBM provider"
mkdir -p ~/.terraform.d/plugins/

# This is for the Terraform validation done in Travis CI which expects these files to exist.
if [[ "$@" == "ci" ]]; then
  touch ~/.ssh/id_rsa
  touch ~/.ssh/id_rsa.pub

  echo "Downloading Terraform and the IBM Terraform provider"
  curl -sLo terraform.zip https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
  curl -sLo ibm-tf-provider.zip https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v0.14.1/linux_amd64.zip

  echo "Unzipping the Terraform and IBM provider binaries into their appropriate directories."
  mkdir bin
  unzip terraform.zip -d bin 
  unzip ibm-tf-provider.zip -d ~/.terraform.d/plugins/
else
  echo "Downloading Terraform and the IBM Terraform provider"
  curl -sLo /tmp/terraform.zip https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
  curl -sLo /tmp/ibm-tf-provider.zip https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v0.14.1/linux_amd64.zip

  echo "Unzipping the Terraform binary to /usr/local/bin/ and the IBM provider binary to ~/.terraform.d/plugins/"
  unzip /tmp/terraform.zip -d /usr/local/bin/
  unzip /tmp/ibm-tf-provider.zip -d ~/.terraform.d/plugins/
fi

echo "Setup complete. Run 'terraform init' in your Terraform directory to initialize the IBM provider"
