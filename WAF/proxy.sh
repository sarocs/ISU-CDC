#!/bin/bash

apt update
apt install nginx -y

ufw allow 'Nginx HTTP'

read -p "Domain: " domain
read -p "Webserver IP: " web_ip

echo -e "server {\n\tlisten 80;\n\tlisten [::]:80;\n\n\t# For personal testing can use _, may need modifications for competition environment\n\tserver_name $domain www.$domain;\n\n\tlocation / {\n\t\tproxy_pass http://$web_ip;\n\t\tinclude proxy_params;\n\t}\n}" > /etc/nginx/sites-available/$domain

ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

systemctl restart nginx
