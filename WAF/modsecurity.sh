#!/bin/bash

read -p "Cores: " cores
read -p "Domain: " domain
dir='/usr/local/modsecurity'

apt update 
apt install -y git g++ gcc libtool autoconf automake build-essential libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre3-dev libssl-dev libxml2-dev libyajl-dev pkgconf zlib1g-dev
mkdir -p $dir
cd $dir

# Build ModSecurity
git clone https://github.com/owasp-modsecurity/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make -j $cores
make install
cd ..

# Build Nginx Connector
git clone https://github.com/owasp-modsecurity/ModSecurity-nginx.git
nginx_version=$(nginx -v 2>&1 | grep -o '[0-9]\.[0-9]*\.[0-9]*')
wget http://nginx.org/download/nginx-$nginx_version.tar.gz
tar xzf nginx-$nginx_version.tar.gz
cd nginx-$nginx_version
./configure --with-compat --with-openssl=/usr/include/openssl/ --add-dynamic-module=$dir/ModSecurity-nginx
make modules
mkdir -p /usr/lib/nginx/modules
cp objs/ngx_http_modsecurity_module.so /usr/lib/nginx/modules/
chmod 644 /usr/share/nginx/modules/ngx_http_modsecurity_module.so
cd ..
sed -i '/include \/etc\/nginx\/modules-enabled\/\*.conf/a\load_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf

# Configure ModSecurity
mkdir /etc/nginx/modsec
wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/owasp-modsecurity/ModSecurity/v3/master/modsecurity.conf-recommended
mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
cp ModSecurity/unicode.mapping /etc/nginx/modsec
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
sed -i '/location/i\\tmodsecurity on;\n\tmodsecurity_rules_file /etc/nginx/modsec/main.conf;' /etc/nginx/sites-enabled/$domain

# Enable OWASP Rules
git clone https://github.com/coreruleset/coreruleset.git
cp coreruleset/crs-setup.conf.example coreruleset/crs-setup.conf
bash -c 'echo "Include /etc/nginx/modsec/modsecurity.conf
Include $(pwd)/coreruleset/crs-setup.conf
Include $(pwd)/coreruleset/rules/*.conf" > /etc/nginx/modsec/main.conf'

# Change Security Action to Redirect
echo -e "SecRuleUpdateActionById 949110 \"t:none,redirect:'%{REQUEST_FILENAME}'\"\nSecRuleUpdateActionById 959100 \"t:none,redirect:'%{REQUEST_FILENAME}'\"" > coreruleset/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

nginx -s reload