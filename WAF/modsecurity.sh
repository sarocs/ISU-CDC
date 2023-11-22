#!/bin/bash

read -p "Cores: " cores
read -p "Domain: " domain
read -p "Install Directory: " dir
sudo apt update 
sudo apt install -y libtool autoconf build-essential libpcre3-dev zlib1g-dev libssl-dev libxml2-dev libgeoip-dev liblmdb-dev libyajl-dev libcurl4-openssl-dev libpcre++-dev pkgconf libxslt1-dev libgd-dev automake
sudo mkdir -p $dir
cd $dir

# Build ModSecurity
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make -j $cores
sudo make install
cd ..

# Build Nginx Connector
git clone https://github.com/SpiderLabs/ModSecurity-nginx.git
nginx_version=$(nginx -v 2>&1 | grep -o '[0-9]\.[0-9]*\.[0-9]*')
wget http://nginx.org/download/nginx-$nginx_version.tar.gz
tar xzf nginx-$nginx_version.tar.gz
cd nginx-$nginx_version
./configure --with-compat --with-openssl=/usr/include/openssl/ --add-dynamic-module=$dir/ModSecurity-nginx
make modules
sudo cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/
sudo chmod 644 /usr/share/nginx/modules/ngx_http_modsecurity_module.so
cd ..
sudo sed -i '/include \/etc\/nginx\/modules-enabled\/*.conf/a\load_module modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf

# Configure ModSecurity
sudo mkdir /etc/nginx/modsec
sudo wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended
sudo mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
sudo cp ModSecurity/unicode.mapping /etc/nginx/modsec
sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
sudo sed -i '/\t}/a\\tmodsecurity on;\n\tmodsecurity_rules_file /etc/nginx/modsec/main.conf;' /etc/nginx/sites-enabled/$domain

# Enable OWASP Rules
git clone https://github.com/coreruleset/coreruleset.git
cp coreruleset/crs-setup.conf.example coreruleset/crs-setup.conf
sudo bash -c 'echo "Include /etc/nginx/modsec/modsecurity.conf
Include $(pwd)/coreruleset/crs-setup.conf
Include $(pwd)/coreruleset/rules/*.conf" > /etc/nginx/modsec/main.conf'

sudo nginx -s reload