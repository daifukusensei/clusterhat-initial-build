#!/bin/bash
#
# Bash script for putting a newly-imaged Cluster HAT controller into a desired state
#
# Original source: Geoff Hudik - https://github.com/thnk2wn/rasp-cat-siren/blob/main/pi-setup/setup.sh
#
# Instructions:
#   1. Physically build Cluster HAT with all four nodes
#   2. Write CNAT Lite Controller image to microSD card for the controller
#   3. Create a file named ssh in /boot directory to enable SSH
#   4. Create a file named wpa_supplicant.conf in /boot directory to allow for initial headless connection via WiFi, replacing XXXX below with the correct network password:
#     country=us
#     update_config=1
#     ctrl_interface=/var/run/wpa_supplicant
#
#     network={
#       ssid="devers"
#       psk="XXXX"
#       id_str="home"
#       priority=4
#     }
#   5. Copy this file to /boot directory, and insert microSD card into controller
#   6. Insert only a single, FAT32-formatted USB drive into any USB port on the controller
#   7. Boot controller from microSD card, using available network tool(s) to find assigned IP
#   8. PuTTY to controller over WiFi with following default credentials:
#       Username: pi
#       Password: clusterctrl
#   9. sudo /boot/clusterhat_controller_setup.sh

echo "Running automated raspi-config tasks"

# Via https://gist.github.com/damoclark/ab3d700aafa140efb97e510650d9b1be
# Execute the config options starting with 'do_' below
grep -E -v -e '^\s*#' -e '^\s*$' <<END | \
sed -e 's/$//' -e 's/^\s*/\/usr\/bin\/raspi-config nonint /' | bash -x -
#

# --- Begin raspi-config non-interactive config option specification ---

# System Configuration
do_hostname p0
do_change_timezone America/Toronto
do_change_locale en_US.UTF-8

# Don't add any raspi-config configuration options after 'END' line below & don't remove 'END' line
END

############# CUSTOM COMMANDS ###########
# You may add your own custom GNU/Linux commands below this line
# These commands will execute as the root user

# Interactively set password for your login. Going through raspi-config w/do_change_pass is slower
sudo passwd pi

echo "Updating hosts file"
sudo bash -c 'echo -e "172.19.181.1    p1\n172.19.181.2    p2\n172.19.181.3    p3\n172.19.181.4    p4" >> /etc/hosts'

echo "Adding static IP addresses to dhcpcd.conf for default WiFi networks"
sudo bash -c 'echo -e "\nssid null\nstatic ip_address=192.168.43.100/24\nstatic routers=192.168.43.1\nstatic domain_name_servers=192.168.43.1" >> /etc/dhcpcd.conf'
sudo bash -c 'echo -e "\nssid Schnauzer\nstatic ip_address=10.0.0.100/24\nstatic routers=10.0.0.1\nstatic domain_name_servers=10.0.0.1" >> /etc/dhcpcd.conf'
sudo bash -c 'echo -e "\nssid devers\nstatic ip_address=172.16.2.100/24\nstatic routers=172.16.2.1\nstatic domain_name_servers=172.16.2.1" >> /etc/dhcpcd.conf'

echo "Adding default WiFi networks to wpa_supplicant.conf with priorities"
sudo bash -c 'read -p "Calvin WiFi password: " wifiPass && echo -e "\nnetwork={\n\tssid=\"Schnauzer\"\n\tpsk=\"$wifiPass\"\n\tid_str=\"calvin\"\n\tpriority=3\n}" >> /etc/wpa_supplicant/wpa_supplicant.conf'
sudo bash -c 'read -p "Mobile WiFi password: " wifiPass && echo -e "\nnetwork={\n\tssid=\"null\"\n\tpsk=\"$wifiPass\"\n\tid_str=\"mobile\"\n\tpriority=1\n}" >> /etc/wpa_supplicant/wpa_supplicant.conf'

echo "Generating SSH key-pair"
sudo -u pi ssh-keygen -b 2048 -t rsa -f /home/pi/.ssh/id_rsa -q -N ''

echo "Creating SSH config file"
sudo -u pi bash -c 'echo -e "Host p1\n\tHostname 172.19.181.1\n\tUser pi" > /home/pi/.ssh/config'
sudo -u pi bash -c 'echo -e "\nHost p2\n\tHostname 172.19.181.2\n\tUser pi" >> /home/pi/.ssh/config'
sudo -u pi bash -c 'echo -e "\nHost p3\n\tHostname 172.19.181.3\n\tUser pi" >> /home/pi/.ssh/config'
sudo -u pi bash -c 'echo -e "\nHost p4\n\tHostname 172.19.181.4\n\tUser pi" >> /home/pi/.ssh/config'

echo "Creating SSH authorized_keys file"
sudo -u pi touch /home/pi/.ssh/authorized_keys

echo "Creating mount directory /media/cluster for USB drive"
sudo mkdir /media/cluster

echo "Adding USB drive to /etc/fstab for auto-mounting upon reboot"
sudo bash -c 'uuid=`sudo blkid -s UUID -o value /dev/sda1` && echo -e "\nUUID=$uuid /media/cluster vfat defaults,users,nofail,noatime,umask=000 0 0" >> /etc/fstab'

echo "Updating packages"
sudo apt-get update && sudo apt-get -y upgrade

echo "Installing NFS server package"
sudo apt-get install nfs-kernel-server -y

echo "Adding /media/cluster to /etc/exports for sharing via NFS"
sudo bash -c 'echo -e "\n/media/cluster 172.19.181.0/24(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports'

echo "Updating table of exports"
sudo exportfs -ra

echo "Installing tmux"
sudo apt-get install tmux -y

echo "Installing Ansible"
sudo apt-get install python-pip -y
sudo pip install ansible

echo "Installing sshpass for initial password-based connection to nodes via Ansible"
sudo apt install sshpass -y

#echo "Installing Docker"
# Installing docker will disconnect ssh
#curl -sSL https://get.docker.com | sh

#echo "Finishing docker setup"
#sudo usermod -aG docker pi

# Reboot after all changes above complete
echo "Restarting to apply changes"
/sbin/shutdown -r now
