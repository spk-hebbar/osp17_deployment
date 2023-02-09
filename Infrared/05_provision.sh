#!/bin/bash -ex

#Unprovision
openstack overcloud delete overcloud -y

openstack overcloud node unprovision --all --stack overcloud -y --network-ports  /home/stack/osp17_deployment/network/baremetal_deploy.yaml

openstack overcloud network unprovision -y /home/stack/osp17_deployment/network/network_data.yaml

rm -f /home/stack/templates/overcloud-networks-deployed.yaml /home/stack/templates/overcloud-vip-deployed.yaml /home/stack/templates/overcloud-baremetal-deployed.yaml

#Prepare
mkdir -p /home/stack/images; cd /home/stack/images
for i in /usr/share/rhosp-director-images/overcloud-full-latest.tar /usr/share/rhosp-director-images/ironic-python-agent-latest.tar; do tar -xvf $i; done
openstack overcloud image upload --image-path /home/stack/images/ --update-existing
for i in $(openstack baremetal node list -c UUID -f value); do openstack overcloud node configure --boot-mode "bios" $i; done


mkdir ~/templates

#Provision
openstack overcloud network provision -y --stack overcloud -o ~/templates/overcloud-networks-deployed.yaml /home/stack/osp17_deployment/network/network_data.yaml

openstack overcloud network vip provision --stack overcloud -y --templates /usr/share/openstack-tripleo-heat-templates  -o ~/templates/overcloud-vip-deployed.yaml  /home/stack/osp17_deployment/network/vip_data.yaml

openstack overcloud node provision --stack overcloud --network-config -y --templates /usr/share/openstack-tripleo-heat-templates  --output ~/templates/overcloud-baremetal-deployed.yaml  /home/stack/osp17_deployment/network/baremetal_deploy.yaml

