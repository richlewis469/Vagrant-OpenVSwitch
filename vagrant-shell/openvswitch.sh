#!/usr/bin/env bash

echo "Entering OpenVSwitch Provisoning"

yum groupinstall  "Development Tools" --assumeyes

yum install rpm-build systemd-units openssl openssl-devel desktop-file-utils \
  groff graphviz procps-ng checkpolicy selinux-policy-devel libcap-ng-devel \
  bridge-utils redhat-rpm-config \
  --assumeyes

yum install kernel-devel kernel-debug-devel \
  kernel-uek-devel kernel-uek-debug-devel \
  --assumeyes

yum install python python-twisted-core python-zope-interface python-six \
  python-sphinx python-devel --assumeyes

cd /usr/local/src

wget http://openvswitch.org/releases/openvswitch-2.8.1.tar.gz
mkdir -p $HOME/rpmbuild/SOURCES
cp openvswitch-2.8.1.tar.gz $HOME/rpmbuild/SOURCES
tar xvf openvswitch-2.8.1.tar.gz
mkdir -p $HOME/rpmbuild/SPECS
cp openvswitch-2.8.1/rhel/*.spec ~/rpmbuild/SPECS
cd $HOME/rpmbuild/SPECS
rpmbuild -ba openvswitch.spec

yum localinstall $HOME/rpmbuild/RPMS/x86_64/openvswitch-2.8.1-1.x86_64.rpm --assumeyes
yum localinstall $HOME/rpmbuild/RPMS/x86_64/openvswitch-devel-2.8.1-1.x86_64.rpm --assumeyes
yum localinstall $HOME/rpmbuild/RPMS/x86_64/openvswitch-debuginfo-2.8.1-1.x86_64.rpm --assumeyes
yum localinstall $HOME/rpmbuild/RPMS/noarch/openvswitch-selinux-policy-2.8.1-1.noarch.rpm --assumeyes

echo "BRCOMPAT=yes" >> /etc/sysconfig/openvswitch

echo "Starting and Testing OpenVSwitch"

ovsdb-tool create

systemctl start openvswitch
systemctl enable openvswitch

ovs-vsctl show

ifconfig eth1
netstat -rn

ADDR=`ifconfig eth1 | grep inet | awk '{print $2}' | head -1`
NETMASK=`ifconfig eth1 | grep inet | awk '{print $4}' | head -1`
GATEWAY=`netstat -rn | grep UG | awk '{print $2}'`

ifconfig eth1 0
ovs-vsctl add-br ovsbr0
ovs-vsctl add-port ovsbr0 eth1
ifconfig ovsbr0 $ADDR netmask $NETMASK

route del default gw $GATEWAY eth1
route add default gw $GATEWAY ovsbr0

ovs-vsctl --version
ovs-vsctl show
ifconfig
netstat -rn
ping -c 5 -I ovsbr0 www.oracle.com

#systemctl restart network

date +"%F %T"
echo "Exiting OpenVSwitch Provisoning"
echo " "
