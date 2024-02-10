read -p "Do you want to enable Active Response (y/n): " ar

curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh && bash ./wazuh-install.sh -a

cp ../ISU-CDC-Private/Wazuh/agent.conf /var/ossec/etc/shared/default
cp ../ISU-CDC-Private/Wazuh/*.xml /var/ossec/etc/rules
cp ../ISU-CDC-Private/Wazuh/audit-key-categories /var/ossec/etc/lists

sed -i '/<list>etc\/lists\/security-eventchannel<\/list>/ a\ \ \ \ <list>etc/lists/audit-key-categories</list>' /var/ossec/etc/ossec.conf

# Customize audit rules
sed -i 's/<rule id="80705" level="3">/<rule id="80705" level="3" ignore="5">/' /var/ossec/ruleset/rules/0365-auditd_rules.xml

# Enable vulnerability scanner
sed -i '/vulnerability-detector/!b;n; s/<enabled>no/<enabled>yes/' /var/ossec/etc/ossec.conf
# Enable Ubuntu vulnerabilites
# Other options: debian, redhat, alas, suse, arch, almalinux
sed -i '/<provider name="canonical">/!b;n; s/<enabled>no/<enabled>yes/' /var/ossec/etc/ossec.conf

# Move active response configuration
ar_conf=$(cat ../ISU-CDC-Private/Wazuh/ar.conf | sed -z 's/\r\n/\\n/g')
sed -i "s~    active-response options here~$ar_conf~" /var/ossec/etc/ossec.conf
# Enable active response
if [ "$ar" != 'n' ]
then
    sed -i '/<!--/ { h; N; /<active-response>/ D; }' /var/ossec/etc/ossec.conf
    sed -i '/<\/active-response>/ { h; n; g; d; }' /var/ossec/etc/ossec.conf
fi

systemctl restart wazuh-manager