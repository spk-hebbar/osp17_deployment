ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null stack@192.168.122.2 bash << EOF
sudo dnf install -y rhosp-director-images-x86_64

mkdir -p ~/images
cd ~/images

tar -xf /usr/share/rhosp-director-images/ironic-python-agent-latest.tar
tar -xf /usr/share/rhosp-director-images/overcloud-full-latest.tar

source ~/stackrc

openstack overcloud image upload

for i in $(openstack baremetal node list -c UUID -f value); do openstack overcloud node configure --boot-mode "bios" $i; done

ls -lhF /var/lib/ironic/httpboot /var/lib/ironic/images

EOF
