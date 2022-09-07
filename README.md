# Programmability Lab Ansible Content

This is a quick rundown of format and file content

## Ansible Config File
[ansible.cfg](ansible.cfg)
  * Turns off Host Key Checking
  * Identifies inventory file as inventory_pod.ini
 
 ## Inventory File
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

## Variable Files
Note: On pod, core and access are named the host ip for each host
  * [group_vars/switches](group_vars/switches)
  * [host_vars/access](host_vars/access)
  * [host_vars/core](host_vars/core)
  
## Templates
  * [templates/access_config.j2](templates/access_config.j2): base config template for access switch
  * [templates/core_config.j2](templates/core_config.j2): base config template for core switch
  * [templates/access_mdt_config.j2](templates/access_mdt_config.j2): empty placeholder mdt template for access switch
  * [templates/core_mdt_config.j2](templates/core_mdt_config.j2): empty placeholder mdt template for core switch

## Roles
[ansible-pyats](https://github.com/CiscoDevNet/ansible-pyats) is installed in this folder

## Playbooks
* Render Template to view Variable Substitutions: [render_configurations.yaml](render_configurations.yaml) uses J2 templates
* Deploy Base Config to Core Switch:  [core_switch_base_config.yaml](core_switch_base_config.yaml) uses core_config.j2 and ansible-pyats role
* Deploy Base Config to Access Switch:  [access_switch_base_config.yaml](access_switch_base_config.yaml) uses access_config.j2 and ansible-pyats role
* Audit Devices using pyATS: [get_switch_info_pyats_parsers.yaml](get_switch_info_pyats_parsers.yaml) uses ansible-pyats role
* Deploy MDT Config to Core Switch:  [core_switch_mdt_config.yaml](core_switch_mdt_config_placeholder.yaml) uses core_mdt_config.j2 and ansible-pyats role
* Deploy MDT Config to Access Switch:  [access_switch_mdt_config_placeholder.yaml](access_switch_mdt_config_placeholder.yaml) uses access_mdt_config.j2 and ansible-pyats role
