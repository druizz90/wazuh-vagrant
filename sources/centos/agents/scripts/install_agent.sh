#!/usr/bin/env bash

# get parameters
master_ip=$1
node_ip=$2
agent_name=$3

# set Wazuh path
wazuh_path="/var/ossec"

# add Wazuh repository
rpm --import http://packages.wazuh.com/key/GPG-KEY-WAZUH
cat > /etc/yum.repos.d/wazuh.repo <<\EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/3.x/yum/
protect=1
EOF

# install epel-release repository
yum install epel-release -y

# install development dependencies for jq library
yum groupinstall "Development Tools"
yum install autoconf automake libtool python -y

# install Python 3
yum install python36 python36-pip python36-devel -y

# install Python libraries
pip3 install pytest freezegun jq

# install Wazuh agent
yum install wazuh-agent -y

# configure Wazuh agent
sed -i "s:MANAGER_IP:$node_ip:g" $wazuh_path/etc/ossec.conf
$wazuh_path/bin/agent-auth -m $master_ip -A $agent_name

# restart Wazuh agent
systemctl restart wazuh-agent
