#-----------------------------------
# WAZUH MANAGER AND API INSTALLATION 
#-----------------------------------

# remove firewalld
yum remove firewalld -y

# install pip and boto3 (for AWS wodle)
yum install epel-release -y
yum -y update
yum -y install python-pip
pip install boto3

# install net-tools
yum install net-tools ntp -y

# install git and zip
yum install git zip -y

# install wget
yum install wget -y

ntpdate -s time.nist.gov

# Wazuh pre-release repository
echo -e '[wazuh_pre_release]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/pre-release/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh_pre.repo

# install Wazuh manager
yum install wazuh-manager -y

# install Node.js
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash - 
yum install nodejs -y 

# install Wazuh API
yum install wazuh-api -y

# configure local_internal_options
echo -e 'wazuh_modules.debug=1\nwazuh_database.sync_syscheck=1' >> /var/ossec/etc/local_internal_options.conf

# enable Wazuh services
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl enable wazuh-api

# run Wazuh manager and Wazuh API
systemctl restart wazuh-manager
systemctl restart wazuh-api
