curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh && bash ./wazuh-install.sh -a

cp ../ISU-CDC-Private/Wazuh/agent.conf /var/ossec/etc/shared/default
cp ../ISU-CDC-Private/Wazuh/fim_custom.xml /var/ossec/etc/rules
cp ../ISU-CDC-Private/Wazuh/command_custom.xml /var/ossec/etc/rules
cp ../ISU-CDC-Private/Wazuh/audit-key-categories /var/ossec/etc/lists

sed -i '/<list>etc\/lists\/security-eventchannel<\/list>/ a\ \ \ \ <list>etc/lists/audit-key-categories</list>' /var/ossec/etc/ossec.conf

# Customize audit rules
sed -i 's/<rule id="80705" level="3">/<rule id="80705" level="3" ignore="5">/' /var/ossec/ruleset/rules/0365-auditd_rules.xml
sed -i 's|</group>||' /var/ossec/ruleset/rules/0365-auditd_rules.xml
# Append to existing audit rules so they take precedence
cat ../ISU-CDC-Private/Wazuh/audit_custom.xml >> /var/ossec/ruleset/rules/0365-auditd_rules.xml

# Enable vulnerability scanner
sed -i '/vulnerability-detector/!b;n; s/<enabled>no/<enabled>yes/' /var/ossec/etc/ossec.conf
# Enable Ubuntu vulnerabilites
# Other options: debian, redhat, alas, suse, arch, almalinux
sed -i '/<provider name="canonical">/!b;n; s/<enabled>no/<enabled>yes/' /var/ossec/etc/ossec.conf

systemctl restart wazuh-manager
tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt