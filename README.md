# Programmability Lab Ansible Content

This is a quick rundown of format and file content

[ansible.cfg](ansible.cfg)
  * Turns off Host Key Checking
  * Identifies inventory file as inventory_pod.ini
  
[inventory_pod.ini](inventory_pod.ini)
NOTE:  device ips not filled see sharepoint or pod
Groups:  
  * access, core, router
  * switches:children:  access, core
Global Variables:
NOTE:  usernames,passwords not filled see sharepoint or pod
  * ansible_network_os=cisco.ios.ios
  * ansible_become
  * ansible_user
  * ansible_become_method=enable
  * ansible_ssh_pass
  * ansible_become_pass

Variable Files:
Note: On pod, core and access are named the host ip for each host
  * [group_vars/switches](group_vars/switches)
  * host_vars/access
  * host_vars/core
  


Deploy initial config:
Core:  core_switch_base_config.yaml references templates/
