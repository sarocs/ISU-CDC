read -p "Do you want to enable Active Response (y/N): " ar
read -p "Wazuh version: " version
read -p "Proxy address: " proxy

curl -sO https://packages.wazuh.com/$version/wazuh-install.sh
echo -e "HTTPS_PROXY=$proxy\nNO_PROXY=localhost,127.0.0.1" | cat - wazuh-install.sh > install.sh
bash ./install.sh -a

cp ../ISU-CDC-Private/Wazuh/agent.conf /var/ossec/etc/shared/default
cp ../ISU-CDC-Private/Wazuh/*.xml /var/ossec/etc/rules
cp ../ISU-CDC-Private/Wazuh/audit-key-categories /var/ossec/etc/lists

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
    r ../ISU-CDC-Private/Wazuh/ar.conf
    d
}" /var/ossec/etc/ossec.conf

# Windows decoders
echo $'<decoder name="tasklist">\n  <prematch>^tasklist: </prematch>\n</decoder>\n' >> /var/ossec/etc/decoders/local_decoder.xml
echo $'<decoder name="net_info">\n  <prematch>^net_info: </prematch>\n</decoder>\n' >> /var/ossec/etc/decoders/local_decoder.xml

systemctl restart wazuh-manager