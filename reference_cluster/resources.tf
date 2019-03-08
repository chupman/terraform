#################################################
# Bastion host
#################################################

resource "ibm_compute_vm_instance" "bastion" {
  hostname = "${var.host_prefix}-bastion"
  domain = "${var.domain}"
  os_reference_code = "${var.bastion_os}"
  datacenter_choice = "${var.datacenter_choice}"
  network_speed = "${var.bastion_nic_speed}"
  hourly_billing = "${var.hourly_billing}"
  private_network_only = false
  tags = "${var.bastion_tags}"
  cores = "${var.bastion_cores}"
  memory = "${var.bastion_memory}"
  disks = "${var.bastion_disk_size}"
  wait_time_minutes = "${var.wait_time_minutes}"
  ssh_key_ids = "${var.ssh_keys}"

  connection {
    host = "${self.ipv4_address}"
    type = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"
  }

  # lifecycle {
  #   prevent_destroy = true

  provisioner "remote-exec" {
    inline = [
    "sudo apt update",
    "sudo apt install python -y",
    ]
  }

  provisioner "local-exec" {
    command = "python ../inventory.py"
  }
}

#################################################
# Cassandra Cluster resources
#################################################

variable "cass_names" {
  default = {
    "0" = "cass01"
    "1" = "cass02"
    "2" = "cass03"
  }
}

resource "ibm_compute_vm_instance" "cass" {
  count = "${var.cass_count}"
  hostname = "${var.host_prefix}-${lookup(var.cass_names, count.index)}"
  domain = "${var.domain}"
  os_reference_code = "${var.cass_os}"
  datacenter_choice = "${var.datacenter_choice}"
  network_speed = "${var.cass_nic_speed}"
  hourly_billing = "${var.hourly_billing}"
  private_network_only = true
  tags = "${var.cass_tags}"
  cores = "${var.cass_cores}"
  memory = "${var.cass_memory}"
  disks = "${var.cass_disk_size}"
  wait_time_minutes = "${var.wait_time_minutes}"
  ssh_key_ids = "${var.ssh_keys}"

  connection {
    host = "${self.ipv4_address_private}"
    type = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"

    bastion_host = "${ibm_compute_vm_instance.bastion.ipv4_address}"
    bastion_private_key = "${file(var.private_key_path)}"
    bastion_user = "ubuntu"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  provisioner "remote-exec" {
    inline = [
    "sudo apt update",
    "sudo apt install python -y",
    ]
  }
}

#################################################
# Elasticsearch Cluster resources
#################################################

variable "es_names" {
  default = {
    "0" = "es01"
    "1" = "es02"
    "2" = "es03"
  }
}

resource "ibm_compute_vm_instance" "es" {
  count = "${var.es_count}"
  hostname = "${var.host_prefix}-${lookup(var.es_names, count.index)}"
  domain = "${var.domain}"
  os_reference_code = "${var.es_os}"
  datacenter_choice = "${var.datacenter_choice}"
  network_speed = "${var.es_nic_speed}"
  hourly_billing = "${var.hourly_billing}"
  private_network_only = true
  tags = "${var.es_tags}"
  cores = "${var.es_cores}"
  memory = "${var.es_memory}"
  disks = "${var.es_disk_size}"
  wait_time_minutes = "${var.wait_time_minutes}"
  ssh_key_ids = "${var.ssh_keys}"

  connection {
    host = "${self.ipv4_address_private}"
    type = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"

    bastion_host = "${ibm_compute_vm_instance.bastion.ipv4_address}"
    bastion_private_key = "${file(var.private_key_path)}"
    bastion_user = "ubuntu"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  provisioner "remote-exec" {
    inline = [
    "sudo apt update",
    "sudo apt install python -y",
    ]
  }
}

#################################################
# Gremlin Server resources
#################################################

variable "gremlin_names" {
  default = {
    "0" = "gremlin01"
    "1" = "gremlin02"
  }
}

resource "ibm_compute_vm_instance" "gremlin" {
  count = "${var.gremlin_count}"
  hostname = "${var.host_prefix}-${lookup(var.gremlin_names, count.index)}"
  domain = "${var.domain}"
  os_reference_code = "${var.gremlin_os}"
  datacenter_choice = "${var.datacenter_choice}"
  network_speed = "${var.gremlin_nic_speed}"
  hourly_billing = "${var.hourly_billing}"
  private_network_only = true
  tags = "${var.gremlin_tags}"
  cores = "${var.gremlin_cores}"
  memory = "${var.gremlin_memory}"
  disks = "${var.gremlin_disk_size}"
  wait_time_minutes = "${var.wait_time_minutes}"
  ssh_key_ids = "${var.ssh_keys}"

  connection {
    host = "${self.ipv4_address_private}"
    type = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"

    bastion_host = "${ibm_compute_vm_instance.bastion.ipv4_address}"
    bastion_private_key = "${file(var.private_key_path)}"
    bastion_user = "ubuntu"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  provisioner "remote-exec" {
    inline = [
    "sudo apt update",
    "sudo apt install python -y",
    ]
  }
}

#################################################
# LoadBalancer for Gremlin Servers
#################################################

resource "ibm_lbaas" "lbaas" {
  name        = "${var.host_prefix}-lbaas"
  description = "Load Balancer for Gremlin Servers"
  type = "PUBLIC"
#  datacenter_choice = "${var.datacenter_choice}"
  subnets = ["${ibm_compute_vm_instance.gremlin.*.private_subnet_id[0]}"]
  protocols = [{
    "frontend_protocol" = "TCP"
    "frontend_port" = 8182
    "backend_protocol" = "TCP"
    "backend_port" = 8182
    "load_balancing_method" = "round_robin"
  }]

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "ibm_lbaas_server_instance_attachment" "lbaas_members" {
  count              = 2
  private_ip_address = "${element(ibm_compute_vm_instance.gremlin.*.ipv4_address_private,count.index)}"
  weight             = 40
  lbaas_id           = "${ibm_lbaas.lbaas.id}"
  depends_on         = ["ibm_lbaas.lbaas"]
}


resource "null_resource" "ansible_setup_and_run" {
  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    host = "${self.ipv4_address}"
    type = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
    "hostname",
    ]
  }

  provisioner "local-exec" {
    command = "python inventory.py --privatekey=${var.private_key_path}"
  }

  provisioner "local-exec" {
    command = "ansible-galaxy install -r ansible/requirements.yml -p ansible/roles"
  }

  provisioner "local-exec" {
    command = "ansible-playbook ansible/playbook.yml"
  }  

  depends_on = [
      "ibm_compute_vm_instance.cass",
      "ibm_compute_vm_instance.es",
      "ibm_compute_vm_instance.gremlin",
  ]

}
