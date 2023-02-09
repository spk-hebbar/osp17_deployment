ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null stack@192.168.122.2 bash << EOF
openstack undercloud install
EOF

#Useful files:

#Password file is at /home/stack/tripleo-undercloud-passwords.yaml
#The stackrc file is at ~/stackrc

#Use these files to interact with OpenStack services, and
#ensure they are secured.

