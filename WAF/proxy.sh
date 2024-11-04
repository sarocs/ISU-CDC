#!/bin/bash

apt update
apt install nginx -y

ufw allow 'Nginx HTTP'

temp="server {
        listen {{port}};

        server_name {{host}}.{{domain}};

        location / {
                proxy_pass http://{{ip}}:{{port}};
                include proxy_params;
        }
}"

read -p "Domain: " domain

while true
do
        read -p "Host: " host
        read -p "IP: " ip
        read -p "Port: " port

        block="${temp//\{\{port\}\}/$port}"
        block="${block//\{\{host\}\}/$host}"
        block="${block//\{\{domain\}\}/$domain}"
        block="${block//\{\{ip\}\}/$ip}"

        echo -e "$block" >> /etc/nginx/sites-available/$domain

        read -p "Do you want to continue? (y/n): " continue
        if [[ "$continue" != "y" ]]; then
                break
        fi
done

ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

systemctl restart nginx
