
## Overall Lab Flow


### Part 1: Ansible Setup Exploration

1. Explore ansible.cfg file

The ansible configuration file contains important Ansible settings.  There are a few ways to identify the ansible configuration that will be used.  See the [Ansible documentation](https://docs.ansible.com/ansible/latest/reference_appendices/config.html) for details.  There are many settings that can be modified, but for the purposes of our lab, we are only going to modify two settings.

1. Specify the inventory file name.  By default, if an inventory file is not specified with the *ansible-playbook <name> -i <inventory-file>*
