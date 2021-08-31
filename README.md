# Cluster HAT build
**A repository of the following:**
- Manual steps and shell script for putting a newly-imaged Cluster HAT controller into my desired state
- Manual steps and Ansible playbooks for putting newly-imaged Cluster HAT nodes into my desired state
- STL of IO shield for ModMyPi's Cluster HAT v1 case that accommodates a 30mm fan
- Various files, scripts and playbooks for configuring and managing the cluster


## Requirements and assumptions
- [Cluster HAT](https://clusterhat.com) module
- Latest [CNAT Lite Controller image](https://clusterctrl.com/setup-software)
- Cluster HAT v1 case from ModMyPi, if printing this repository's STL file
- Building the Cluster HAT with all four nodes


## Initial setup instructions
1. Physically build Cluster HAT with all four nodes
2. Write CNAT Lite Controller image to microSD card for the controller
3. Create a file named **ssh** in **/boot** directory to enable SSH
4. Create a file named **wpa_supplicant.conf** in **/boot** directory to allow for initial headless connection via WiFi, replacing XXXX below with the correct network password:
      ```
      country=us
      update_config=1
      ctrl_interface=/var/run/wpa_supplicant

      network={
        ssid="devers"
        psk="XXXX"
        id_str="home"
        priority=4
      }
      ```
5. Copy **controller_setup_script/clusterhat_controller_setup.sh** from this repository to **/boot** directory of controller's microSD card, and insert into controller
6. For each node, write the CNAT Lite Controller image to microSD card
7. For each node, change **" quiet init=/sbin/reconfig-clusterctrl TYPE"** in **cmdline.txt** in **/boot** directory, replacing TYPE with "p1", "p2", "p3 or "p4" for each specific node
8. Create a file named **ssh** in **/boot** directory of each node's microSD card to enable SSH
9. Create a file named **wpa_supplicant.conf** in **/boot** directory of each node's microSD card to allow for initial headless connection via WiFi, replacing XXXX below with the correct network password:
      ```
      country=us
      update_config=1
      ctrl_interface=/var/run/wpa_supplicant

      network={
        ssid="devers"
        psk="XXXX"
        id_str="home"
        priority=4
      }
      ```
10. Insert microSD cards into their respective nodes
11. Insert only a single, FAT32-formatted USB drive into any USB port on the controller
12. Boot controller from microSD card, using available network tool(s) to find assigned IP
13. PuTTY to controller over WiFi with following default credentials:
     - Username: pi
     - Password: clusterctrl
14. `sudo /boot/clusterhat_controller_setup.sh`
15. `cd /media/cluster`
16. `clusterctrl on`
17. `sudo git clone https://github.com/daifukusensei/clusterhat-build.git`
18. `cd clusterhat-build/ansible`
19. `ansible-playbook -i hosts playbooks/clusterhat_nodes_setup.yml -k`
