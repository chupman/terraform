# terraform   [![BUILD](https://travis-ci.org/chupman/terraform.svg?branch=master)](https://travis-ci.org/chupman/terraform)

## Getting Started

To get started you must find your IBM Cloud API username and API key. To find them log into [control.softlayer.com](https://control.softlayer.com), click on your profile and then scroll down to the **API Access Information** Section. The values you'll need are **API Username** and **Authentication Key**

Once you have your credentials you can use them with either environment variables by populating `exports.sh` or as hidden terraform variables by copying `secrets.auto.tfvars.example` in the `reference_cluster` folder to `secrets.auto.tfvars.example`. 

## Make a copy of the reference_cluster folder
If you wish to deploy multiple clusters It's best to just copy the whole folder 

```
$ cp -r reference_cluster prefix_name_cluster 
```

### Credentials with Environment variables
in `ibmcloud_exports` you'll want to replace  the values for `SL_USERNAME` and `SL_API_KEY` with the credentials you found in your profile. **Note** `BM_API_KEY` is not currently used in this example, but would be necessary if bluemix services were added on. 
```
# ibmcloud_exports
export BM_API_KEY="bm_api_key"
export SL_USERNAME="sl_username"
export SL_API_KEY="sl_api_key"
```

### Credentials with Terraform variables
`secrets.auto.tfvars` will need to be created and populated for any deployment making it a very convenient place add your IBM Cloud credentials. To get started copy `secrets.auto.tfvars.example` to `secrets.auto.tfvars` if you haven't already and fill in the values for `ibm_sl_username` and `ibm_sl_api_key`.

```
ibm_bmx_api_key = ""
ibm_sl_username = ""
ibm_sl_api_key = ""
ssh_keys = []
private_key_path = "~/.ssh/id_rsa.pub"
public_key_path = "~/.ssh/id_rsa"
domain = "mydomain.com"
```

### Define environment specific variables
Copy `secrets.auto.tfvars.example` to `secrets.auto.tfvars` 

To use this repo to deploy JanusGraph to IBM Cloud using terraform you must first setup API keys and get your username.

Once we deploy our infrastructure we're going to use ansible to setup Cassandra ,ElasticSearch, and JanusGraph
