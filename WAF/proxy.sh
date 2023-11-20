#!/bin/bash

apt update
apt -y full-upgrade
apt install nginx

#ufw allow 'Nginx HTTP'

read -p "Domain: " domain
read -p "Webserver IP: " web_ip

#Not sure about www.domain for competitions
echo "server {
    listen 80;
    listen [::]:80;

    server_name $domain www.$domain;
        
    location / {
        proxy_pass $web_ip;
        include proxy_params;
    }
}" > /etc/nginx/sites-available/$domain

ln -s /etc/nginx/site-available/$domain /etc/nginx/sites-enabled/

systemctl restart nginx
