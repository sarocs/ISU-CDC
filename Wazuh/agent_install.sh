#!/bin/bash

read -p "Wazuh manager IP: " ip

# Add Wazuh package repository
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt update

# Install Wazuh agent
WAZUH_MANAGER=$ip apt install wazuh-agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

# Disable Wazuh package repository
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
apt update

# Move FIM script to expected location
mv register_files.sh /root
chmod 750 /root/register_files.sh

# Install auditd and rules
apt -y install auditd

mv ../ISU-CDC-Private/Wazuh/audit.rules /etc/audit/audit.rules
auditctl -R /etc/audit/audit.rules

sh -c 'echo "wazuh_command.remote_commands=1" >> /var/ossec/etc/local_internal_options.conf'
sh -c 'echo "logcollector.remote_commands=1" >> /var/ossec/etc/local_internal_options.conf'

systemctl restart wazuh-agent