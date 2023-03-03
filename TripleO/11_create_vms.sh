# Prepare VM images for Trex and l3fwd/testpmd in the hypervisor

# use RHEL 8 since trex does not work on rhel 9
base_url="http://download.eng.brq.redhat.com/rhel-8/rel-eng/RHEL-8/latest-RHEL-8.6"
url="$base_url/compose/BaseOS/x86_64/images"
curl -LO "$url/SHA256SUM"
qcow2=$(sed -nre 's/^SHA256 \((rhel-guest-image.+\.qcow2)\) =.*/\1/p' SHA256SUM)
curl -LO "$url/$qcow2"
sha256sum -c --ignore-missing SHA256SUM
mv -v "$qcow2" rhel-guest-image-8.6.qcow2

cp rhel-guest-image-8.6.qcow2 trex.qcow2
cp rhel-guest-image-8.6.qcow2 l3fwd.qcow2

# set common options for both trex and l3fwd
set --      --smp 8 --memsize 8192
set -- "$@" --run-command "rm -f /etc/yum.repos.d/*.repo"
set -- "$@" --run-command "curl -L $base_url/repofile.repo > /etc/yum.repos.d/rhel.repo"
set -- "$@" --root-password password:redhat

export LIBGUESTFS_BACKEND=direct

#For Mellanox NICs, use the following
#--run-command "curl -L https://content.mellanox.com/ofed/MLNX_OFED-5.7-1.0.2.0/MLNX_OFED_LINUX-5.7-1.0.2.0-rhel8.6-x86_64.tgz | tar -C /root -zx" \
#--run-command "cd /root/MLNX_OFED* && ./mlnxofetinstall --without-fw-update" \

#TODO: Trex requires 2 SRIOV VFs to be passed,  how to do that?
virt-customize -a trex.qcow2 "$@" \
    --install pciutils,driverctl,tmux,vim,python3,tuned-profiles-cpu-partitioning,tcpdump,httpd \
    --run-command "curl -L https://trex-tgn.cisco.com/trex/release/v3.02.tar.gz | tar -C /root -zx && mv /root/v3.02 /root/trex" \
    --run-command "systemctl enable httpd  && sed -i 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config" \
    --selinux-relabel

#TODO: l3fwd requires 2 virtio interfaces, again how?
virt-customize -a l3fwd.qcow2 "$@" \
    --install pciutils,dpdk,dpdk-tools,python3,numactl-devel,tuned-profiles-cpu-partitioning,driverctl,vim,tmux,tcpdump,httpd \
    --run-command "systemctl enable httpd  && sed -i 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config" \
    --selinux-relabel

#Copy the images to undercloud
scp trex.qcow2 l3fwd.qcow2 stack@192.168.122.2:/home/stack/
