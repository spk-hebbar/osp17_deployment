ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null stack@192.168.122.2 << EOF
source ~/stackrc
openstack overcloud node import ~/osp17_deployment/TripleO/instack.json
sleep 20
openstack overcloud node introspect --all-manageable --provide

EOF
