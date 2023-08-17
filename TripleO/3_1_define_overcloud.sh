url="http://download.eng.brq.redhat.com/rhel-9/rel-eng/RHEL-9/latest-RHEL-9.0/compose/BaseOS/x86_64/images"
curl -LO "$url/SHA256SUM"
qcow2=$(sed -nre 's/^SHA256 \((rhel-guest-image.+\.qcow2)\) =.*/\1/p' SHA256SUM)
curl -LO "$url/$qcow2"
sha256sum -c --ignore-missing SHA256SUM
mv -v "$qcow2" /var/lib/libvirt/images/rhel-guest-image-9.0.qcow2

# create an empty image for the compute-0
compute_0_img=/var/lib/libvirt/images/compute_0.qcow2
compute_1_img=/var/lib/libvirt/images/compute_1.qcow2
qemu-img create -f qcow2 $compute_0_img 80G
qemu-img create -f qcow2 $compute_1_img 80G

virt-resize --expand /dev/sda4 \
        /var/lib/libvirt/images/rhel-guest-image-9.0.qcow2 $compute_0_img
virt-resize --expand /dev/sda4 \
        /var/lib/libvirt/images/rhel-guest-image-9.0.qcow2 $compute_1_img

virt-install --ram 16384 --vcpus 8 --cpu host --os-variant rhel9.0 --import \
    --graphics none --autoconsole none \
    --disk "path=$compute_0_img,device=disk,bus=virtio,format=qcow2" \
    --network network=ctlplane,mac=52:54:00:ca:ca:02 \
    --network network=user1 \
    --network network=user2 \
    --name overcloud-compute-0 \
    --dry-run --print-xml > compute-0.xml
virsh define --file compute-0.xml

virt-install --ram 16384 --vcpus 8 --cpu host --os-variant rhel9.0 --import \
    --graphics none --autoconsole none \
    --disk "path=$compute_1_img,device=disk,bus=virtio,format=qcow2" \
    --network network=ctlplane,mac=52:54:00:ca:ca:03 \
    --network network=user1 \
    --network network=user2 \
    --name overcloud-compute-1 \
    --dry-run --print-xml > compute-1.xml
virsh define --file compute-1.xml

dnf install python3-pip -y
pip3 install virtualbmc

# start the virtual bmc daemon
#vbmcd
# define and start one virtual BMC on port 6230
vbmc add overcloud-compute-0 --port 6231 --username admin --password admin
vbmc add overcloud-compute-1 --port 6232 --username admin --password admin

vbmc start overcloud-compute-0
vbmc start overcloud-compute-1
vbmc list
