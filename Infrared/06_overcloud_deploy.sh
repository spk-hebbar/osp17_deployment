#!/bin/bash

openstack overcloud delete overcloud -y

BUILTINS=/usr/share/openstack-tripleo-heat-templates/environments

echo "Creating roles..."
#openstack overcloud roles generate -o $HOME/roles_data.yaml Controller ComputeOvsDpdk

echo "Deploying pre-provisioned overcloud nodes...."
openstack overcloud deploy $PARAMS \
    --templates /usr/share/openstack-tripleo-heat-templates \
    --ntp-server clock.redhat.com,time1.google.com,time2.google.com,time3.google.com,time4.google.com \
    --stack overcloud \
    -r /home/stack/osp17_deployment/roles_data.yaml \
    -n /home/stack/osp17_deployment/network/network_data.yaml \
    --deployed-server \
    -e /home/stack/templates/overcloud-baremetal-deployed.yaml \
    -e /home/stack/templates/overcloud-networks-deployed.yaml \
    -e /home/stack/templates/overcloud-vip-deployed.yaml \
    -e $BUILTINS/services/neutron-ovn-dpdk.yaml \
    -e $BUILTINS/disable-telemetry.yaml \
    -e $BUILTINS/debug.yaml \
    -e $BUILTINS/config-debug.yaml \
    -e /home/stack/osp17_deployment/environment.yaml \
    -e /home/stack/osp17_deployment/network-environment.yaml \
    -e /home/stack/osp17_deployment/network-environment-regular.yaml \
    -e /home/stack/osp17_deployment/ml2-ovs-nfv.yaml \
    -e /home/stack/containers-prepare-parameter.yaml \
    --log-file overcloud_deployment.log
