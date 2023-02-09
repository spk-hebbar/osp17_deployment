ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null stack@192.168.122.2 << EOF
source ~/stackrc

#Unprovision
openstack overcloud delete overcloud -y

openstack overcloud node unprovision --all --stack overcloud -y --network-ports  /home/stack/osp17_deployment/TripleO/network/baremetal_deploy_compute_sriov.yaml

openstack overcloud network unprovision -y /home/stack/osp17_deployment/TripleO/network/network_data.yaml

rm -f /home/stack/templates/overcloud-networks-deployed.yaml /home/stack/templates/overcloud-vip-deployed.yaml /home/stack/templates/overcloud-baremetal-deployed.yaml


mkdir ~/templates

#openstack overcloud role generate -o ~/roles_data.yaml Controller ComputeOvsDpdk ComputeSriov Compute

#Provision
openstack overcloud network provision -y --stack overcloud -o ~/templates/overcloud-networks-deployed.yaml /home/stack/osp17_deployment/TripleO/network/network_data.yaml

openstack overcloud network vip provision --stack overcloud -y --templates /usr/share/openstack-tripleo-heat-templates  -o ~/templates/overcloud-vip-deployed.yaml  /home/stack/osp17_deployment/TripleO/network/vip_data.yaml

openstack overcloud node provision --stack overcloud --network-config -y --templates /usr/share/openstack-tripleo-heat-templates  --output ~/templates/overcloud-baremetal-deployed.yaml  /home/stack/osp17_deployment/TripleO/network/baremetal_deploy_compute_sriov.yaml
EOF

