# Scripts for ISU's Cyber Defense Competitions

## joinAD.sh
Script to join Ubuntu servers to an active directory domain using realmd.
The script is specifically designed for CDC domain names but could easily
be changed to any other domain. Requires three arguments box_name=`<name>`
team_num=`<number>` ad_ip=`<ip address>`. Tested on Ubuntu server LTS 14, 16,
18, 20, 22.

## add_users.ps1
Powershell script to add users and their information to an active directory
server from a CSV file.