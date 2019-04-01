#!/usr/bin/env python
# encoding: utf-8
"""
inventory.py

This script creates a site.yaml file for use with the ansible playbook
contained at ansible/playbook.yaml

Created by Chris Hupman on 2019-01-25.
Copyright (c) 2019 IBM. All rights reserved.
"""

import os
import json
from argparse import ArgumentParser
 
LOG = None
 
def parse_args():
    parser = ArgumentParser('Ansible inventory from tfstate')
    parser.add_argument('--tfstate', '-t', action='store', default='terraform.tfstate', help='Terraform state file in current or specified directory (terraform.tfstate default)')
    parser.add_argument('--privatekey', '-pk', action='store', default='~/.ssh/id_rsa', help='Fully qualified path of the ssh private key to use')

    return parser.parse_args()

def getPrivateIPsByTag(tags, tag):
    private_ip_list = []
    for i in range(min(3, len(tags[tag]))):
        private_ip_list.append(tags[tag][i]['private_ip'])
    return ','.join(map(str, private_ip_list))
 
class CreateInventoryFile(object):
    def __init__(self):
        # Define the tags that match to ansible groups
        self.roles = set(["jg-cass", "jg-es", "jg-gremlin", "bastion"])
        self.tags = {}
        self.args = parse_args()
        self.rootdir = os.getcwd()
        self.filename = self.args.tfstate
        self.privatekeypath = self.args.privatekey
        self.tfstate = self.open_tfstate()

    def run(self):
        self.writeInventoryFile(self.parseTfstate())

    def open_tfstate(self):
        return json.load(open(self.filename))

    def parseTfstate(self):
        for module in self.tfstate['modules']:
            for resource in module['resources'].values():
                # iterate through each VM instance and get inventory info
                if resource['type'] == 'ibm_compute_vm_instance':
                    attrs = resource['primary']['attributes']
                    for k in attrs:
                        if k.startswith('tags.') and attrs[k] in self.roles:
                            if attrs[k] not in self.tags:
                                self.tags[attrs[k]] = []
                            self.tags[attrs[k]].append(
                                {'name': attrs['hostname'],
                                 'ip': attrs['ipv4_address'],
                                 'private_ip': attrs['ipv4_address_private'],
                                 'private_subnet': attrs['private_subnet']})
        return self.tags

    def writeInventoryFile(self, tags):
        write_es_master = False
        if not os.path.exists("inventory"):
            os.makedirs("inventory")
        with open("inventory/site.yaml", "w+") as f:
            for tag in tags:
                f.write("[" + tag + "]\n")
                for host in tags[tag]:
                    if "01" in host['name'] and tag == "jg-es":
                        write_es_master = True
                        es_master_name = host['name']
                        es_master_ip = host['private_ip']
                    if host['ip'] != "":
                        f.write(host['name'] + " ansible_host=" + host['ip'] + "\n")
                    else:
                        f.write(host['name'] + " ansible_host=" + host['private_ip'] + "\n")
                f.write("[" + tag + ":vars]\n")
                f.write("private_subnet=" + tags[tag][0]['private_subnet'] + "\n")
                if "bastion" in tags:
                    self.writeSshConfig(tags["bastion"])
                    f.write("bastion_ip=" + tags["bastion"][0]['private_ip'] + "\n")
                if "jg-cass" == tag:
                    f.write("cassandra_seeds=" + getPrivateIPsByTag(tags, tag) + "\n")
                if "jg-es" == tag:
                    f.write("es_hosts=" + getPrivateIPsByTag(tags, tag) + "\n")
                if "jg-gremlin" == tag:
                    f.write("es_hosts=" + getPrivateIPsByTag(tags, "jg-es") + "\n")
                    f.write("cass_hosts=" + getPrivateIPsByTag(tags, "jg-cass") + "\n")
                if write_es_master:
                    f.write("es_master_ip=" + es_master_ip + "\n")
                    f.write("[jg-es-master]\n")
                    f.write(es_master_name + " ansible_host=" + es_master_ip + "\n")
                    write_es_master = False

    def writeSshConfig(self, host):
        ssh_config_file = os.path.join(self.rootdir, 'ssh.config')
        ssh_config_file_template = os.path.join(self.rootdir, 'ssh.config.template')
        with open(ssh_config_file_template, 'r') as f:
            filedata = f.read()
        filedata = filedata.replace('REPLACE_WITH_IP', host[0]['ip'])
        filedata = filedata.replace('REPLACE_WITH_PEM_PATH', self.privatekeypath)
        with open(ssh_config_file, 'w') as f:
            f.write(filedata)

if __name__ == '__main__':
    cif = CreateInventoryFile()
    cif.run()
