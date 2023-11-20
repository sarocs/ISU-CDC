#!/bin/bash

apt update
apt -y full-upgrade
apt -y install nginx

ufw allow 'Nginx HTTP'

read -p "Domain: " domain
read -p "Webserver IP: " web_ip

echo "server {
    listen 80;
    listen [::]:80;

    # For personal testing can use _, may need modifications for competition environment
    server_name $domain www.$domain;
        
    location / {
        proxy_pass http://$web_ip;
        include proxy_params;
    }
}" > /etc/nginx/sites-available/$domain

ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

systemctl restart nginx
