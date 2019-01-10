###############################################################################
# Shared Configuration Options
###############################################################################

# Credentials are set with Environment Variables
provider "ibm" {}

### If you wish to set you credentials statically use this block instead.
# provider "ibm" {
#     bluemix_api_key = ""
#     softlayer_username = ""
#     softlayer_api_key = ""
# }

variable "datacenter_choice" {
  description = "Lists of datacenter to use"
  default = [
    {
      datacenter = "sjc01"
    },
#    {
#      datacenter = "sjc03"
#    },
#    {
#      datacenter = "sjc04"
#    },
#    {
#      datacenter = "sea01"
#    }
  ]
}
variable "public_key_path" {
  description = "Public key path"
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Fully qualified path to ssh private key"
  default = "/Users/chupman/.ssh/id_rsa"
} 

variable "host_prefix" {
  description = "cluster resource name prefix"
  default = "chupman"
}

variable "ssh_keys" {
  description = "ssh keys to add to the hosts"
  default = 1224997
}

variable "wait_time_minutes" {
  description = "Time to wait before deploying resources"
  default = 90
}

variable "hourly_billing" {
  description = "True is hourly billing is desired, false if monthly billing is preferred"
  default = true
}

variable "domain" {
  description = "Domain for deployed resources"
  default = "cloud.ibm.com"
}
###############################################################################
# Cassandra Cluster Options
###############################################################################

variable "cass_os" {
  description = "OS for Dassandra cluster nodes"
  default = "UBUNTU_18_64"
}

variable "cass_memory" {
  description = "Amount for memory allocated for Cassandra cluster nodes"
  default = 8192
}

variable "cass_cores" {
  description = "Number of cores for Cassandra cluster nodes"
  default = 4
}

variable "cass_nic_speed" {
  description = "NIC speed for Cassandra cluster nodes"
  default = 100
}

variable "cass_disk_size" {
  description = "Disk size for Cassandra cluster nodes"
  default = [100]
}

variable "cass_tags" {
  description = "Tags for Cassandra cluster nodes"
  default = ["jg-cass"]
}

variable "cass_count" {
  description = "Number of Cassandra nodes to deploy"
  default = 3
}

###############################################################################
# Elasticsearch Cluster Options
###############################################################################

variable "es_os" {
  description = "OS for Elasticsearch cluster nodes"
  default = "UBUNTU_18_64"
}

variable "es_memory" {
  description = "Amount for memory allocated for Elasticsearch cluster nodes"
  default = 8192
}

variable "es_cores" {
  description = "Number of cores for Elasticsearch cluster nodes"
  default = 4
}

variable "es_nic_speed" {
  description = "NIC speed for Elasticsearch cluster nodes"
  default = 100
}

variable "es_disk_size" {
  description = "Disk size for Elasticsearch cluster nodes"
  default = [100]
}

variable "es_tags" {
  description = "Tags for Elasticsearch cluster nodes"
  default = ["jg-es"]
}

variable "es_count" {
  description = "Number of Elasticsearch nodes to deploy"
  default = 3
}

###############################################################################
# Gremlin Server  Options
###############################################################################

variable "gremlin_os" {
  description = "OS for Gremlin Server  nodes"
  default = "UBUNTU_18_64"
}

variable "gremlin_memory" {
  description = "Amount for memory allocated for Gremlin Server nodes"
  default = 8192
}

variable "gremlin_cores" {
  description = "Number of cores for Gremlin Server nodes"
  default = 4
}

variable "gremlin_nic_speed" {
  description = "NIC speed for Gremlin Server nodes"
  default = 100
}

variable "gremlin_disk_size" {
  description = "Disk size for Gremlin Server nodes"
  default = [100]
}

variable "gremlin_tags" {
  description = "Tags for Gremlin Server nodes"
  default = ["jg-gremlin"]
}

variable "gremlin_count" {
  description = "Number of Gremlin Server nodes to deploy"
  default = 2
}

###############################################################################
# Bastion Server  Options
###############################################################################

variable "bastion_os" {
  description = "OS for bastion Server node"
  default = "UBUNTU_18_64"
}

variable "bastion_memory" {
  description = "Amount for memory allocated for Bastion Server nodes"
  default = 8192
}

variable "bastion_cores" {
  description = "Number of cores for Bastion Server nodes"
  default = 4
}

variable "bastion_nic_speed" {
  description = "NIC speed for Bastion Server nodes"
  default = 100
}

variable "bastion_disk_size" {
  description = "Disk size for Bastion Server nodes"
  default = [100]
}

variable "bastion_tags" {
  description = "Tags for Bastion Server nodes"
  default = ["bastion"]
}
