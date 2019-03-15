#!/bin/bash
os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
# Cygwin Not actually tested. Feedback from a Cygwin user is welcomed.
if [[ $os_type == "cygwin"* ]]; then
  os_type="windows"
fi

echo "OS type is ${os_type}"
if [ ! -d ~/.terraform.d/plugins ]; then
  echo "Creating the Terraform plugins directory in ~/.terraform.d/plugins/ so Terraform can find the IBM provider"
  mkdir -p ~/.terraform.d/plugins/
fi

# This is for the Terraform validation done in Travis CI which expects these files to exist.
if [[ "$@" == "ci" ]]; then
  touch ~/.ssh/id_rsa
  touch ~/.ssh/id_rsa.pub
  tf_dir=bin/
  dl_dir=./
else
  tf_dir=/usr/local/bin/
  dl_dir=/tmp/
fi

if [ ! -f "${tf_dir}terraform" ]; then
  echo "Downloading Terraform"
  curl -sLo ${dl_dir}terraform.zip https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_${os_type}_amd64.zip
  echo "Creating bin directory and unzipping the Terraform binary to bin/"
  mkdir ${tf_dir}
  unzip ${dl_dir}terraform.zip -d "${tf_dir}"
else
  echo "Found Terraform binary in ${tf_dir}, skipping download"
fi

# Allow for cases where there are multiple IBM provider version in the plugins folder.
ibm_providers=(~/.terraform.d/plugins/terraform-provider-ibm*)

if [ ! -e ${ibm_providers[0]} ]; then
  echo "Downloading the IBM Terraform provider"
  curl -sLo ${dl_dir}ibm-tf-provider.zip https://github.com/IBM-Cloud/terraform-provider-ibm/releases/latest/download/${os_type}_amd64.zip
  echo "Unzipping the IBM provider binary to ~/.terraform.d/plugins/"
  unzip ${dl_dir}ibm-tf-provider.zip -d ~/.terraform.d/plugins/
else
  echo "IBM provider found in ~/.terraform.d/plugins/, skipping download"
fi

echo "Setup complete. Run 'terraform init' in your Terraform cluster directory to initialize the IBM provider"
