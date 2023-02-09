# as stack@dirlo
# Install red hat internal certificate. This is required to use the internal container
# images registry without declaring it as "insecure".

ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null stack@192.168.122.2 bash << EOF
sudo curl -Lo /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt \
        https://password.corp.redhat.com/RH-IT-Root-CA.crt
sudo update-ca-trust extract

# enable OSP repositories
sudo dnf install -y \
        http://download.eng.brq.redhat.com/rcm-guest/puddles/OpenStack/rhos-release/rhos-release-latest.noarch.rpm
sudo rhos-release 17.0
sudo dnf update -y
sudo dnf install -y vim

# only required if there was a kernel upgrade
# after reboot is complete, ssh stack@192.168.122.2 back in the undercloud vm
sudo systemctl reboot
EOF
