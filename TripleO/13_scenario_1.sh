#Get L3 connectivity between 2 subnets

#To have L2 connectivity between 2 VMs of compute0 and compute1
# provider1 ---subnet1------VM-Trex-----subnet2------provider2
# provider1----subnet1------VM-L3fwd----subnet2------provider2
# ping from subnet1 of VM-Trex to subnet1 of VM-L3fwd happens via L2 connectivity
# ping from subnet2 of VM-Trex to subnet2 of VM-L3fwd happens via L2 connectivity
# ping across subnets won't happen
# subnet1 - 172.16.101.0/24 eth1 of VM-Trex and VM-L3fwd
# subnet2 - 172.16.102.0/24 eth2 of VM-Trex and VM-L3fwd
# ping 172.16.101.x -I eth1 --> won't work
# ping 172.16.102.x -I eth0 --> won't work

### Login to compute-0
ovs-vsctl add-port eno1 br-provider1
ovs-vsctl add-port eno2 br-provider2
ovs-vsctl set port eno1 tag=109
ovs-vsctl set port eno2 tag=116
ping 172.16.102.157 -I eth1
ping 172.16.101.48 -I eth0

###Login to compute-1
ovs-vsctl add-port eno1 br-provider1
ovs-vsctl add-port eno2 br-provider2
ovs-vsctl set port eno1 tag=109
ovs-vsctl set port eno2 tag=116
ping 172.16.102.44 -I eth1
ping 172.16.101.59 -I eth0



#To have L3 connectivity between 2 VMs across subnets
# provider1----subnet1----router_1----subnet2----provider2
# ping from subnet1 of VM-Trex to subnet2 of VM-L3fwd happens via router_1
# ping from subnet2 of VM-Trex to subnet1 of VM-L3fwd happens via router_1
# ping 172.16.101.x -I eth1 --> should work
# ping 172.16.102.x -I eth0 --> should work

### In undercloud
openstack router create router_1
openstack subnet list

#Get the router-id
router_id=$(openstack router show router_1 -f value -c id)

#Get the list of subnets
subnet_ids=$(openstack subnet list -f value -c ID)
for subnet_id in $subnet_ids; do
    echo "Adding subnet $subnet_id to router $router_id..."
    openstack router add subnet $router_id $subnet_id
done

# To get the ip addresses of the ports attached to router
openstack port list --router $router_id

### login to compute0 VM-L3fwd
ip r a 172.16.102.0/24 via 172.16.101.1 dev eth0
ip r a 172.16.101.0/24 via 172.16.102.1 dev eth1
ping 172.16.102.157 -I eth0
ping 172.16.101.48 -I eth1

### login to compute1 VM-Trex
ip r a 172.16.102.0/24 via 172.16.101.1 dev eth0
ip r a 172.16.101.0/24 via 172.16.102.1 dev eth1
ping 172.16.102.44 -I eth0
ping 172.16.101.59 -I eth1
