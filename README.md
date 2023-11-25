# Scripts for ISU's Cyber Defense Competitions

## joinAD.sh
Script to join Ubuntu servers to an active directory domain using realmd.
The script is specifically designed for CDC domain names but could easily
be changed to any other domain. Tested on Ubuntu server LTS 14, 16,
18, 20, 22.

## add_users.ps1
Powershell script to add users and their information to an active directory
server from a CSV file.

## proxy.sh
Script to install Nginx and set it up as a reverse proxy.

## modsecurity.sh
Script to install the ModSecurity web application firewall on an Nginx proxy and
enable the OWASP core rule set. `proxy.sh` should be ran before running this script. 
By default, ModSecurity takes disruptive action by returning an HTTP 403 code.
This script modifies the rules to redirect back to the request's url.