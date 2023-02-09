git clone https://github.com/redhat-openstack/infrared.git /root/infrared
cd /root/infrared
source .venv/bin/activate
infrared virsh -vv --host-address ${SERVER} --host-key ~/.ssh/id_rsa --cleanup yes
