# Programmability Lab Ansible Content

This is a quick rundown of format and file content

ansible.cfg:  turns of host key checking and specifies inventory file

Hosts File:  inventory.ini

Variable Files: 
  * group_vars/switches
  * host_vars/.  (1 file for core switch and 1 for access switch)
Deploy initial config:
Core:  core_switch_base_config.yaml references templates/
