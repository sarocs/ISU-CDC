#!/bin/bash

GREEN="\e[1;32m"
RED="\e[31m"
END="\e[0m"

echo -e "${GREEN}Checking crontab...${END}\n"

users=$(cat /etc/passwd | awk -F ':' '{print $1}')
cron="n"
for user in $users
do
	temp=$(sudo crontab -u $user -l 2>/dev/null)
	if [ $? -eq 0 ]
	then
		echo -e "${RED}$user has cronjobs listed in crontab${END}"
		cron="y"
	fi
done
if [ cron="y" ]
then
	echo -e "Run crontab -u <username> -l to see found cronjobs\n"
fi
echo -e "${RED}Check other cron in /etc${END}\n"

echo -e "${GREEN}Checking users with a shell...${END}\n"
users=$(grep -E -v "/bin/false|/usr/sbin/nologin|/sbin/nologin|/bin/sync|/sbin/halt|/sbin/shutdown" /etc/passwd | awk -F ':' '{print $1}')

for user in $users
do
	echo -e "${RED}$user has login shell${END}"
done


echo -e "\n${GREEN}Open ports...${END}\n"
sudo netstat -tulpne

echo -e "\n${GREEN}Services...${END}\n"
systemctl list-units --all | grep -E -v "dev|sys-devices"

echo -e "\n${GREEN}Checking for password \"cdc\"...${END}\n"
PASSWORD="cdc"

for username in $users
do
	uid=$(id -u "$username")
	expect &>/dev/null << EOF
		set timeout 2
		spawn su - $username
		expect {
			"Password:" {
				send "$PASSWORD\r"
				expect {
					"su: Authentication failure" {
						exit 1
					}
					"$username" {
						exit 3
					}
				}
			}
			timeout {
				exit 2
			}
		}
EOF
	if [ $? -eq 3 ]
	then
		echo "$username has password $PASSWORD"
	fi
done

echo -e "\n${GREEN}Shadow permissions...${END}\n"
ls -l /etc/shadow

echo -e "\n${GREEN}SUID/SGID files...${END}\n"
find / -perm -4000 -print
find / -perm -2000 -print

