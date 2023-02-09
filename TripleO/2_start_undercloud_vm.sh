yum install libguestfs libguestfs-tools-c virt-install -y

# download the latest RHEL 9.0 image
url="http://download.eng.brq.redhat.com/rhel-9/rel-eng/RHEL-9/latest-RHEL-9.0/compose/BaseOS/x86_64/images"
curl -LO "$url/SHA256SUM"
qcow2=$(sed -nre 's/^SHA256 \((rhel-guest-image.+\.qcow2)\) =.*/\1/p' SHA256SUM)
curl -LO "$url/$qcow2"
sha256sum -c --ignore-missing SHA256SUM
mv -v "$qcow2" /var/lib/libvirt/images/rhel-guest-image-9.0.qcow2

# create an empty image for the undercloud
undercloud_img=/var/lib/libvirt/images/undercloud.qcow2
qemu-img create -f qcow2 $undercloud_img 80G
# copy the default RHEL image into it (expanding the main partition)
virt-resize --expand /dev/sda4 \
    /var/lib/libvirt/images/rhel-guest-image-9.0.qcow2 $undercloud_img

# assign a static IP address to the interface connected to br-mgmt
undercloud_net="nmcli connection add type ethernet ifname eth0 con-name mgmt"
undercloud_net="$undercloud_net ipv4.method static"
undercloud_net="$undercloud_net ipv4.address 192.168.122.2/24"
undercloud_net="$undercloud_net ipv4.gateway 192.168.122.1"
#dns_servers=$(sed -nre 's/^nameserver //p' /etc/resolv.conf | xargs echo)
dns_servers=10.38.5.26,10.45.248.15
undercloud_net="$undercloud_net ipv4.dns '$dns_servers'"

# customize the image
# the VM must *NOT* be called "director" or "director.*". It will interfere with
# the undercloud deployment which alters /etc/hosts on the undercloud vm. This causes
# issues during deployment.
virt-customize -a $undercloud_img --smp 4 --memsize 4096 \
    --hostname undercloud.redhat.local --timezone UTC \
    --uninstall cloud-init \
    --run-command "useradd -s /bin/bash -m stack" \
    --write "/etc/sudoers.d/stack:stack ALL=(root) NOPASSWD:ALL" \
    --chmod "0440:/etc/sudoers.d/stack" \
    --password stack:password:stack \
    --ssh-inject "stack:file:/root/.ssh/id_rsa.pub" \
    --firstboot-command "$undercloud_net" \
    --firstboot-command "nmcli connection up mgmt" \
    --selinux-relabel

# define and start the virtual machine
virt-install --ram 32768 --vcpus 8 --cpu host --os-variant rhel9.0 --import \
    --graphics none --autoconsole none \
    --disk "path=$undercloud_img,device=disk,bus=virtio,format=qcow2" \
    --network network=management \
    --network network=ctlplane \
    --name undercloud-director
