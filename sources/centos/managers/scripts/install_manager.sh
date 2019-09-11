#!/usr/bin/env bash

# get parameters
master_ip=$1
node_ip=$2
node_type=$3
node_name=$4
wazuh_branch=$5

# set Wazuh path
wazuh_path="/var/ossec"

# install dependencies
yum install make gcc policycoreutils-python automake autoconf libtool epel-release git which sudo wget -y

# install development dependencies for jq library
yum groupinstall "Development Tools"

# install Python 3
yum install python36 python36-pip python36-devel -y

# install Python libraries
pip3 install pytest freezegun jq

# install Wazuh
cd / && git clone https://github.com/wazuh/wazuh && cd /wazuh && git checkout ${wazuh_branch} && cd /
# build Python dependencies
sed -i 's!--index-url=file://${ROUTE_PATH}/${EXTERNAL_CPYTHON}/Dependencies/simple!!' /wazuh/src/Makefile
cp /vagrant/configurations/preloaded-vars.conf /wazuh/etc/preloaded-vars.conf
/wazuh/install.sh

if [ "X$node_type" == "Xmaster" ]; then
    cp /vagrant/configurations/master-ossec.conf $wazuh_path/etc/ossec.conf
elif [ "X$node_type" == "Xworker" ]; then
    cp /vagrant/configurations/worker-ossec.conf $wazuh_path/etc/ossec.conf
fi

# add cluster configuration
sed -i "s:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g" $wazuh_path/etc/ossec.conf
sed -i "s:<node>NODE_IP</node>:<node>$master_ip</node>:g" $wazuh_path/etc/ossec.conf
sed -i -e "/<cluster>/,/<\/cluster>/ s|<disabled>[a-z]\+</disabled>|<disabled>no</disabled>|g" $wazuh_path/etc/ossec.conf
sed -i "s:<node_name>node01</node_name>:<node_name>$node_type</node_name>:g" $wazuh_path/etc/ossec.conf

if [ "X$node_type" != "Xmaster" ]; then
    sed -i "s:<node_type>master</node_type>:<node_type>worker</node_type>:g" $wazuh_path/etc/ossec.conf
fi

# enable syscheck DB
echo 'wazuh_database.sync_syscheck=1' >> $wazuh_path/etc/local_internal_options.conf

# restart Wazuh
$wazuh_path/bin/ossec-control restart
