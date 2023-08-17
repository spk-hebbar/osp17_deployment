# as stack@dirlo
#Wait for the undercloud VM to come up
sleep 30
ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null stack@192.168.122.2 bash << EOF
sudo dnf install -y python3-tripleoclient



# as stack@dirlo
openstack tripleo container image prepare default \
    --local-push-destination \
    --output-env-file ~/containers-prepare-parameter.yaml

openstack overcloud container image prepare --namespace=registry-proxy.engineering.redhat.com/rh-osbs --push-destination=undercloud.ctlplane.localdomain:8787 --prefix=rhosp17-openstack-  --output-env-file=/home/stack/templates/overcloud_images.yaml --output-images-file /home/stack/local_registry_images.yaml

sudo openstack overcloud container image upload   --config-file  /home/stack/local_registry_images.yaml   --verbose

git clone https://github.com/spk-hebbar/osp17_deployment.git
cp /home/stack/osp17_deployment/TripleO/undercloud.conf /home/stack/
EOF
