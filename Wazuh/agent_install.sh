#!/bin/bash

read -p "Wazuh manager IP: " ip

if [[ -f /etc/debian_version ]]
then
    # Add Wazuh package repository
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
    apt update

    # Install Wazuh agent
    WAZUH_MANAGER="$ip" apt install -y wazuh-agent


    # Disable Wazuh package repository
    sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
    apt update

    # Install auditd
    apt install -y auditd

elif [[ -f /etc/redhat-release ]]
then
    # Add Wazuh package repository
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
    cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

    # Install Wazuh agent
    WAZUH_MANAGER="$ip" yum install -y wazuh-agent

    # Disable Wazuh package repository
    sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo

    # Install auditd
    yum -y install audit
fi

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

# Move FIM script to expected location
# mv register_files.sh /root
# chmod 750 /root/register_files.sh

# Install auditd rules
mv ../ISU-CDC-Private/Wazuh/audit.rules /etc/audit/audit.rules
auditctl -R /etc/audit/audit.rules

# sh -c 'echo "wazuh_command.remote_commands=1" >> /var/ossec/etc/local_internal_options.conf'
sh -c 'echo "logcollector.remote_commands=1" >> /var/ossec/etc/local_internal_options.conf'

systemctl restart wazuh-agent