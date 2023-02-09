#!/bin/bash
###########################################################
# This script runs on the hypervisor node ################
###########################################################

set -ex

if [ "$#" -lt 2 ]; then
    echo "ERROR: Invalid Arguments"
    exit 1
fi

RELEASE=$1
SERVER=$2
ARGS="${@:3}"

#git clone osp17_deployment



cd /root

#Update VLAN_id in network_data.yaml file
#awk -v var=100 'BEGIN{x=var+1;FS="\\n"}/vlan:/{gsub(/vlan:.*/,"vlan: "x++)} {print}' /root/osp17_deployment/network/network_data.yaml > network_data.yaml

# Modify based on OSP release changes
#####################################
VERSION13="7.9"
VERSION16_1="8.2.0"
VERSION16_2="8.4"
VERSION17_0="8.4"
VERSION17_0_RHEL9="9.0"
#####################################

echo "Deploying OSP version $RELEASE"
MAJ=${RELEASE%.*}
if echo $RELEASE | grep -qe '\.' ; then
    MIN=${RELEASE#*.}
else
    MIN=""
fi

echo "Deploying OSP Major (${MAJ}) and Minor (${MIN}) Version"

BASE7="http://download.eng.brq.redhat.com/rhel-7/rel-eng/RHEL-7/latest-RHEL-@VERSION@/compose/Server/x86_64/images"
BASE8="http://download.eng.brq.redhat.com/rhel-8/rel-eng/RHEL-8/latest-RHEL-@VERSION@/compose/BaseOS/x86_64/images"
BASE9="http://download.eng.brq.redhat.com/rhel-9/rel-eng/RHEL-9/latest-RHEL-@VERSION@/compose/BaseOS/x86_64/images"

if [[ $MAJ -lt 16 ]]; then
    BASE=${BASE7/@VERSION@/$VERSION13}
elif [[ $MAJ -eq 16 ]]; then
    if [[ $MIN -eq 1 || $MIN -eq 2 ]]; then
        if [[ $MIN -eq 2  ]]; then
            BASE=${BASE8/@VERSION@/$VERSION16_2}
        elif [[ $MIN -eq 1 ]]; then
            BASE=${BASE8/@VERSION@/$VERSION16_1}
        fi
    else
        echo "Unsupported release - ${RELEASE}"
        exit 1
    fi
elif [[ $MAJ -eq 17 ]]; then
    BASE=${BASE9/@VERSION@/$VERSION17_0_RHEL9}
fi

MD5="$BASE/MD5SUM"
LINE=$(curl -s $MD5 | grep 'guest-image')
LINE=${LINE%:*}
LINE=${LINE#\# }
IMG="${BASE}/${LINE}"
# Verify if the URL is valid
curl -s --head $IMG | grep -q "200 OK"
echo "Base OS Image used - ${IMG}"
##############################################################################

UCIDR=`cat osp17_deployment/undercloud.conf |grep ^local_ip|awk 'BEGIN{FS=OFS="="} {print $2}'|sed "s/ //g"`
UIP=${UCIDR%/*}
UIP_PREFIX=${UIP%.*}

CNTRL_ARGS=" -e  override.networks.net1.ip_address=${UIP_PREFIX}.150 "

ECIDR=$(cat osp17_deployment/network/network_data.yaml |awk 'BEGIN{RS="-";FS=""}{print}'|awk -v var="name_lower: external" 'BEGIN{RS="\\n\\n";FS="\\n"} $0~var{print }'|awk 'BEGIN{FS="";}/ip_subnet:/{print}'|awk 'BEGIN{FS=OFS=":"} {print $2}'|sed "s/'//g"|sed "s/ //g")
EIP=${ECIDR%/*}
EIP=${EIP%.*}
NET_ARGS=" -e  override.networks.net4.ip_address=$EIP.1 -e  override.networks.net4.dhcp.range.start=$EIP.2  -e  override.networks.net4.dhcp.range.end=$EIP.100  -e  override.networks.net4.dhcp.subnet_cidr=$EIP.0/24  -e  override.networks.net4.dhcp.subnet_gateway=$EIP.1   -e  override.networks.net4.floating_ip.start=$EIP.101 -e  override.networks.net4.floating_ip.end=$EIP.151 "

BOOT_MODE="bios"

echo "Setting boot mode ($BOOT_MODE) for ($SERVER)"

cd /root/infrared
source .venv/bin/activate

infrared virsh -vv -o provision.yml --host-address ${SERVER} --host-key ~/.ssh/id_rsa --image-url ${IMG} --host-memory-overcommit False --disk-pool /home/ -e override.controller.cpu=4 -e override.undercloud.cpu=4 -e override.controller.memory=10240 -e override.undercloud.memory=24576 ${CNTRL_ARGS} ${NET_ARGS} ${ARGS} --bootmode ${BOOT_MODE}
