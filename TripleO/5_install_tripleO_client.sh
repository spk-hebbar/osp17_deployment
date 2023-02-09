# as stack@dirlo
#Wait for the undercloud VM to come up
sleep 30
ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null stack@192.168.122.2 bash << EOF
sudo dnf install -y python3-tripleoclient



# as stack@dirlo
#openstack tripleo container image prepare default \
 #   --local-push-destination \
  #  --output-env-file ~/containers-prepare-parameter.yaml

git clone https://github.com/spk-hebbar/osp17_deployment.git
cp osp17_deployment/TripleO/undercloud.conf /home/stack/
cp osp17_deployment/TripleO/containers-prepare-parameter.yaml /home/stack/
EOF
