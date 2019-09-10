#!/usr/bin/env bash

master_ip=$1
worker_ip=$2
agent_name=$3
repo=$4

ossec_path="/var/ossec"

echo -e '[wazuh_staging]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/staging/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh_pre.repo
yum update

if [ "X$repo" = "Xpre-release" ]
then
  yum install -y wazuh-agent
else
  yum install -y wazuh-agent-3.5.0-1
fi

cp /vagrant/ossec_agents.conf $ossec_path/etc/ossec.conf
sed -i "s:MANAGER_IP:$worker_ip:g" $ossec_path/etc/ossec.conf
$ossec_path/bin/agent-auth -m $master_ip -A $agent_name
systemctl restart wazuh-agent
