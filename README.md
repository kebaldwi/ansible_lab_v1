# Programmability Lab Ansible Content. -- Out of Date!!!

This is a quick rundown of format and file content

## Ansible Config File
[ansible.cfg](ansible.cfg)
  * Turns off Host Key Checking
  * Identifies inventory file as inventory_pod.ini
  * Extends Roles Path
 
 ## Inventory File
[inventory_pod.ini](inventory_pod.ini)
NOTE:  device ips not filled see sharepoint or pod

Groups:  
  * access, core, wan
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
  * [host_vars/access_switch](host_vars/10.1.#.15)
  * [host_vars/core_switch](host_vars/10.1.#.14)
  
## Templates

  * [templates/access_config.j2](templates/access_config.j2): base config template for access switch
  * [templates/core_config.j2](templates/core_config.j2): base config template for core switch
  * [templates/telemetry_config.j2](templates/telemetry_config.j2): MDT config template for switches

## Roles
[ansible-pyats](https://github.com/CiscoDevNet/ansible-pyats) is installed in this folder

## Playbooks
* Render Template to view Variable Substitutions: [render_configurations.yaml](Task_0_Fact_Finding/render_configurations.yaml) uses J2 templates
* Deploy Base Config to Core Switch:  [core_switch_base_config.yaml](Task_1_Apply_Base_Configuration/core_switch_base_config.yaml) uses core_config.j2 and ansible-pyats role
* Deploy Base Config to Access Switch:  [access_switch_base_config.yaml](Task_1_Apply_Base_Configuration/access_switch_base_config.yaml) uses access_config.j2 and ansible-pyats role
* Audit Devices using pyATS: [get_switch_info_pyats_parsers.yaml](Task_0_Fact_Finding/get_switch_info_pyats_parsers.yaml) uses ansible-pyats role
* Deploy MDT Config to Switches:  [Task_2_Apply_MDT_Configuration/switch_MDT_config.yaml](core_switch_MDT_config_placeholder.yaml) uses core_mdt_config.j2 and ansible-pyats role
* Deploy Change to router using Ansible Resource Module: [Task_1.5_Day_N_Config_Change/router_hostname.yaml](Task_1.5_Day_N_Config_Change/router_hostname.yaml)

## Lab Guide

[Lab Guide Part 1](LabGuide.md)  
[Lab Guide Part 2](LabGuide_Part2.md)  
[Lab Guide Part 3](LabGuide_Part3.md)  
[Lab Guide Part 4](LabGuide_Part4.md)  

