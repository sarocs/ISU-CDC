read -p "Do you want to enable Active Response (y/N): " ar
read -p "Wazuh version: " version
read -p "Proxy address: " proxy

curl -sO https://packages.wazuh.com/$version/wazuh-install.sh
echo -e "export HTTPS_PROXY=$proxy\nexport NO_PROXY=localhost,127.0.0.1" | cat - wazuh-install.sh > install.sh
bash ./install.sh -a

cp config/agent.conf /var/ossec/etc/shared/default
cp config/*.xml /var/ossec/etc/rules
cp config/audit-key-categories /var/ossec/etc/lists
chown wazuh:wazuh /var/ossec/etc/lists/audit-key-categories
chmod 660 /var/ossec/etc/lists/audit-key-categories

sed -i '/<list>etc\/lists\/security-eventchannel<\/list>/ a\ \ \ \ <list>etc/lists/audit-key-categories</list>' /var/ossec/etc/ossec.conf

# Customize audit rules
sed -i 's/<rule id="80705" level="3">/<rule id="80705" level="3" ignore="5">/' /var/ossec/ruleset/rules/0365-auditd_rules.xml

# Enable active response
if [ "$ar" = 'y' ]
then
    sed -i '/<!--/ { h; N; /<active-response>/ D; }' /var/ossec/etc/ossec.conf
    sed -i '/<\/active-response>/ { h; n; g; d; }' /var/ossec/etc/ossec.conf
fi
# Move active response configuration
sed -i "/    active-response options here/{
    r config/ar.conf
    d
}" /var/ossec/etc/ossec.conf

# Windows decoders
echo $'<decoder name="tasklist">\n  <prematch>^tasklist: </prematch>\n</decoder>\n' >> /var/ossec/etc/decoders/local_decoder.xml
echo $'<decoder name="net_info">\n  <prematch>^net_info: </prematch>\n</decoder>\n' >> /var/ossec/etc/decoders/local_decoder.xml

systemctl restart wazuh-manager