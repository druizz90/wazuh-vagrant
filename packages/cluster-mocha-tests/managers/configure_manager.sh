#!/usr/bin/env bash

master_ip=$1
manager_type=$2
node_name=$3

if [ "X${manager_type}" = "Xmaster" ]
then
    ossec_path="/var/ossec"
    ossec_conf="/var/ossec/etc/ossec.conf"
    echo -e '[wazuh_pre_release]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/pre-release/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh_pre.repo
else
    ossec_path="/opt/ossec"
    ossec_conf="/opt/ossec/etc/ossec.conf"
    echo -e '[wazuh_pre_release]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/pre-release/opt/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh_pre.repo
fi
yum install wazuh-manager -y

cp /vagrant/ossec_master.conf /var/ossec/etc/ossec.conf

curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
yum install nodejs -y    
npm config set user 0
yum install wazuh-api -y
API_CONF_FOLDER=$ossec_path/api/configuration
PRECONF_FILE=${API_CONF_FOLDER}/preloaded_vars.conf
cat <<EOT >> ${PRECONF_FILE}
HTTPS=Y
AUTH=Y
COUNTRY="US"
STATE="State"
LOCALITY="Locality"
ORG_NAME="Org Name"
ORG_UNIT="Org Unit Name"
COMMON_NAME="Common Name"
PASSWORD="password"
USER=foo
PASS=bar
PORT=55000
PROXY=N
EOT

$ossec_path/api/scripts/configure_api.sh

sed -i "s:config.experimental_features  = false;:config.experimental_features = true;:g" $ossec_path/api/configuration/config.js
sed -i "s:config.cache_enabled = \"yes\";:config.cache_enabled = \"no\";:g" $ossec_path/api/configuration/config.js

systemctl restart wazuh-api

if [ "X${manager_type}" = "Xmaster" ]
then
    

    $ossec_path/bin/ossec-control enable agentless
    $ossec_path/bin/ossec-control enable client-syslog
    $ossec_path/bin/ossec-control enable integrator

    cat << EOT >> $ossec_path/etc/local_internal_options.conf
    wazuh_database.sync_syscheck=1
EOT

else
    sed -i "s:<node_type>master</node_type>:<node_type>worker</node_type>:g" $ossec_path/etc/ossec.conf
fi

sed -i "s:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g" $ossec_conf
sed -i "s:<bind_addr>0.0.0.0</bind_addr>:<bind_addr>$master_ip</bind_addr>:g" $ossec_conf
sed -i "s:<node>NODE_IP</node>:<node>$master_ip</node>:g" $ossec_conf
sed -i -e "/<cluster>/,/<\/cluster>/ s|<disabled>[a-z]\+</disabled>|<disabled>no</disabled>|g" $ossec_conf
sed -i "s:<node_name>node01</node_name>:<node_name>$node_name</node_name>:g" $ossec_conf
systemctl restart wazuh-manager

if [ "X${manager_type}" = "Xmaster" ]
then
    $ossec_path/bin/ossec-maild
    $ossec_path/bin/ossec-authd
fi

yum install -y git
git clone https://github.com/wazuh/wazuh-api.git -b 3.9
cd ./wazuh-api
npm install mocha -g
npm install glob supertest mocha should moment

echo "Configure OK"

