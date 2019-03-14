#!/bin/bash

usage()
{
    echo "usage: add_to_known_hosts.sh  [[--add hostname ] | [--delete hostname]| [-h]]"
}

hostname=""
add=false

while [ "$1" != "" ]; do
    case $1 in
        -a | --add )        shift
                            hostname=$1
                            add=true
                            ;;
        -d | --delete )     shift
                            hostname=$1
                            ;;
        -h | --help )       usage
                            exit
                            ;;
        * )                 usage
                            exit 1
    esac
    shift
done

if [ "$hostname" = "" ]; then
    echo "no hostname passed. Exiting.";
    exit 1;
fi

# Remove any existing known_hosts entry matching the passed ip or hostname. 
# This will not catch both. Creates backup in case it's used incorrectly outside of Terraform.
sed -i.bak "/$hostname/d" ~/.ssh/known_hosts

# Add remote host's public keys to known_hosts
if $add ; then
  ssh-keyscan $hostname 2> /dev/null | grep -v '^#' >> ~/.ssh/known_hosts
fi

