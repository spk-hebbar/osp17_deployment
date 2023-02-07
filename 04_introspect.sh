#!/bin/bash
###########################################################
# This script runs on the hypervisor node ################
###########################################################

# For this to happen, all nodes must be in manageable state
# Check that with "openstack baremetal node list" from undercloud

set -ex

if [ "$#" -ne 1 ]; then
    echo "ERROR: Invalid Arguments, provide release tag, eg:17.1"
    exit 1
fi

RELEASE=$1
THT_PATH=base_deployment
SERVER=`hostname`

BOOT_MODE='bios'

echo "Setting boot mode ($BOOT_MODE) for ($SERVER)"

echo "Deploying OSP version ${RELEASE}"

cd /root/infrared/
source .venv/bin/activate

infrared tripleo-overcloud -vv -o prepare_instack.yml --version ${RELEASE} --introspect=yes --tagging=yes --deploy=no --deployment-files ${THT_PATH} -e provison_virsh_network_name=br-ctlplane --hybrid instack.json --vbmc-host hypervisor  --boot-mode ${BOOT_MODE}

