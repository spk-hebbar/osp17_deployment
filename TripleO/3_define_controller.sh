url="http://download.eng.brq.redhat.com/rhel-9/rel-eng/RHEL-9/latest-RHEL-9.0/compose/BaseOS/x86_64/images"
curl -LO "$url/SHA256SUM"
qcow2=$(sed -nre 's/^SHA256 \((rhel-guest-image.+\.qcow2)\) =.*/\1/p' SHA256SUM)
curl -LO "$url/$qcow2"
sha256sum -c --ignore-missing SHA256SUM
mv -v "$qcow2" /var/lib/libvirt/images/rhel-guest-image-9.0.qcow2

# create an empty image for the controller
controller_img=/var/lib/libvirt/images/controller.qcow2
qemu-img create -f qcow2 $controller_img 80G

virt-resize --expand /dev/sda4 \
        /var/lib/libvirt/images/rhel-guest-image-9.0.qcow2 $controller_img

virt-install --ram 16384 --vcpus 4 --cpu host --os-variant rhel9.0 --import \
    --graphics none --autoconsole none \
    --disk "path=$controller_img,device=disk,bus=virtio,format=qcow2" \
    --network network=ctlplane,mac=52:54:00:ca:ca:01 \
    --network network=user1 \
    --network network=user2 \
    --name overcloud-controller \
    --dry-run --print-xml > controller.xml
virsh define --file controller.xml

dnf install python3-pip -y
pip3 install virtualbmc

# start the virtual bmc daemon
vbmcd
# define and start one virtual BMC on port 6230
vbmc add overcloud-controller --port 6230 --username admin --password admin
vbmc start overcloud-controller
vbmc list
