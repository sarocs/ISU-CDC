for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    KEY_LENGTH=${#KEY}
    VALUE="${ARGUMENT:$KEY_LENGTH+1}"

    export "$KEY"="$VALUE"
done

hostnamectl set-hostname $box_name.team$team_num.isucdc.com
apt update
apt upgrade -y
apt install -y realmd ntp
sed -i "/pool 0.ubuntu.pool.ntp.org iburst/i server ad.team$team_num.isucdc.com" /etc/ntp.conf
realm discover team$team_num.isucdc.com
sleep 10
#echo "This will fail but installs the necessary packages"
#realm join team$team_num.isucdc.com
apt install -y krb5-user
# enter TEAM5.ISUCDC.COM
kinit administrator
realm join team$team_num.isucdc.com
sleep(10)
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
service sssd --full-restart
sed -i "/pam_unix.so/a session required\tpam_mkhomedir.so skel=/etc/skel/ umask=0022" /etc/pam.d/common-session
sed -i "/%admin ALL=(ALL) ALL/a \\n# Allow Domain Admins to use sudo\n%Domain\ Admins@team$team_num.isucdc.com ALL=(ALL) NOPASSWD:ALL\n%Administrators@team$team_num.isucdc.com ALL=(ALL) NOPASSWD:ALL" /etc/sudoers
# realm permit -g group@domain
realm permit --all
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
service ssh restart
reboot