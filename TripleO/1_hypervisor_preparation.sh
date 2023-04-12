#disable avahi daemon as it messes up with network manager
systemctl disable --now avahi-daemon.socket
systemctl disable --now avahi-daemon.service

#eno1 in hypervisor -- br-user1 bridge-- user1 network -- enp2s0 interface in controller
#eno2 in hypervisor -- br-user2 bridge -- user2 network -- enp3s0 interface in controller
#eno4 in hypervisor -- br-ctrl bridge -- ctrl network -- enp1s0 interface in controller


# prepare bridges for libvirt networks
#nmcli connection del eno4 eno1 br-ctrl br-user
################### Method 1 #########################################
#for br in br-ctrl br-user; do
#    nmcli connection add con-name $br type bridge ifname $br \
#        ipv4.method disabled ipv6.method disabled
#done
#nmcli connection add con-name eno4 type ethernet ifname eno4 master br-ctrl
#nmcli connection add con-name eno1 type ethernet ifname eno1 master br-user
#
#for c in eno4 eno1 br-ctrl br-user; do
#   nmcli connection up $c
#done
#####################################################################

################# Method 2 ##########################################
for br in br-ctrl br-user1 br-user2; do
	ip link add name $br type bridge
done

ip link set eno4 master br-ctrl
ip link set eno1 master br-user1
ip link set eno2 master br-user2

for c in eno4 eno1 eno2 br-ctrl br-user1 br-user2; do
	ip link set $c up
done
#####################################################################

################ Method 3 ###########################################
# Create bridge interfaces
#for br in br-ctrl br-user; do
#    brctl addbr $br
#done
#
## Add interfaces to the bridges
#brctl addif br-ctrl eno4
#brctl addif br-user eno1

####################################################################

dnf install libvirt -y
systemctl enable --now libvirtd.socket

# no DHCP on the management network
# we need to have a static IP for the undercloud
cat > /tmp/management.xml <<EOF
<network>
  <name>management</name>
  <ip address="192.168.122.1" prefix="24"/>
  <bridge name="br-mgmt"/>
  <forward mode="nat" dev="eno3"/>
</network>
EOF
cat > /tmp/ctlplane.xml <<EOF
<network>
  <name>ctlplane</name>
  <bridge name="br-ctrl"/>
  <forward mode="bridge"/>
</network>
EOF
cat > /tmp/user1.xml <<EOF
<network>
  <name>user1</name>
  <bridge name="br-user1"/>
  <forward mode="bridge"/>
</network>
EOF
cat > /tmp/user2.xml <<EOF
<network>
  <name>user2</name>
  <bridge name="br-user2"/>
  <forward mode="bridge"/>
</network>
EOF

# remove libvirt default network
virsh net-destroy --network default
virsh net-undefine --network default

for net in management ctlplane user1 user2; do
    virsh net-destroy $net
    virsh net-undefine $net
done

for net in management ctlplane user1 user2; do
    virsh net-define "/tmp/$net.xml"
    virsh net-autostart $net
    virsh net-start $net
done

virsh net-list
