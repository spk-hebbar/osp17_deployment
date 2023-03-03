#Previous step has created VMs in hypervisor and copied them to undercloud /home/stack

#SSH to undercloud and install these images, create network, subnet, security groups, flavor and server
ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null stack@192.168.122.2 bash << EOF

source ~/overcloudrc

openstack image create --min-disk 10 --min-ram 2048 --disk-format qcow2 --container-format bare --file ~/trex.qcow2 --public trex

openstack image create --min-disk 10 --min-ram 2048 --disk-format qcow2 --container-format bare --file ~/l3fwd.qcow2 --public l3fwd
openstack image list

#Create provider1 network
openstack network create --provider-network-type vlan --provider-physical-network datacentre1 --external provider1 --provider-segment 109

#Create provider2 network
openstack network create --provider-network-type vlan --provider-physical-network datacentre2 --external provider2 --provider-segment 116

openstack network list

#Create subnet for provider
openstack subnet create --subnet-range 172.16.101.0/24 --network provider1  provider1-subnet
openstack subnet create --subnet-range 172.16.102.0/24 --network provider2  provider2-subnet

openstack subnet list

#Create flavor
openstack flavor create  --ram 2048 --disk 10 --vcpus 1 small
openstack flavor list

#Create security group
openstack security group create fortnox
openstack security group show fortnox

#Create security rule
openstack security group rule create --ingress --protocol icmp fortnox
openstack security group rule create --ingress --protocol tcp fortnox
openstack security group rule create --ingress --protocol udp fortnox
openstack security group show fortnox

openstack compute service list
openstack host list
openstack hypervisor list

#trex is run on Computesriov-0 and l3fwd is run on Compute-0/Computedpdk-0
openstack server create --image l3fwd --security-group fortnox --network provider1 --network provider2 --flavor small vm-l3fwd --availability-zone nova:compute-0.localdomain

openstack server create --image trex --security-group fortnox --network provider1 --network provider2 --flavor small vm-trex --availability-zone nova:computesriov-0.localdomain


openstack server list
openstack server show vm-l3fwd
openstack server show vm-trex

EOF
