
## Overall Lab Flow


### Part 1: Ansible Setup Exploration

#### Explore ansible.cfg file

The ansible configuration file contains important Ansible settings.  There are a few ways to identify the ansible configuration that will be used.  See the [Ansible documentation](https://docs.ansible.com/ansible/latest/reference_appendices/config.html) for details.  There are many settings that can be modified.  To generate an ansible.cfg file with base options, run:  
`ansible-config init --disabled > example_ansible.cfg`

To generate an ansible.cfg file with existing plugins, run:  
`ansible-config init --disabled -t all > example_ansible_all.cfg`

In our ansible.cfg, we are taking all defaults except for two settings:

1. Specifying the inventory file name.  By default, if an inventory file is not specified with the *ansible-playbook playbook_name -i inventory-file_name* switch, the inventory file name specified in the ansible.cfg file will be used.  We are modifying this setting to our inventory file name, inventory_pod.ini with this line:  
`inventory = inventory_pod.ini`  

2. Disabling strict host key checking.  When we SSH to a device for the first time, we will be asked if we trust the ssh key of the host.  If we choose yes, the ssh key for the host will be added to our known-hosts file.  

```
The authenticity of host '10.88.64.17 (10.88.64.17)' can't be established.  
RSA key fingerprint is SHA256:TUs+SFgw+lv2VKGAVoWd9ZFSZsJEA0G91cAKf3tqCf0.  
Are you sure you want to continue connecting (yes/no/[fingerprint])?   
```

This process can cause issues for our Ansible Playbook run if we are connecting to a device for the first time.  For the purposes of our lab, we are going to disable this behavior and avoid this check with this line:

`host_key_checking = False`

For security reasons, we likely wouldn't do this in production.  

#### Explore the Inventory file

Let's take a look at the inventory file.  The inventory file can be in many formats, but is generally either in ini or YAML format.  See the [Ansible Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) on inventories.  Our Inventory file is in ini format. 

```
[access]  
10.1.2.121 

[core]  
10.1.2.122

[router]  
10.1.2.123 

[switches:children]  
access  
core  

[all:vars]  
ansible_network_os=cisco.ios.ios  
ansible_become=yes  
ansible_user=  
ansible_become_method=enable  
ansible_ssh_pass=  
ansible_become_password=  
```

Some items to note about our inventory files.  We define a group with the \[groupname\] notation.  To create a group of groups, we can use \[groupname:children\].  We can define variables for a group or a host in the inventory file with the \[groupname:vars\] or \[hostname:vars\] notation.  There is also an implicit group called **all**.  So, \[all:vars\] contains the variables that apply to all devices in the inventory.    


#### Explore Variable Files and Directories

There are many ways to define variables for use in our playbooks.  As we have just explored, we can define variables in our inventory files, but that can lead to complex and hard to manage inventory files.  Alternatively, we can also define them in our group_vars and host_vars folders and in our playbooks themselves.  Let's explore some of these other options.

#### Variables Directories

Let's explore our group_vars and host_vars directories:

```
├──group_vars
|  └──switches
├──host_vars
|  ├──10.1.2.121
|  └──10.1.2.122

```

In the group_vars folder we have a file called **switches**, which contains the variables that apply to the devices in the group **switches** as defined in our inventory file.

In the host_vars folder, we have 2 files.  Each file corresponds to a specific device defined in the inventory file.  So the file titled **10.1.2.121** contains variables that apply specifically to the host 10.1.2.121. 

If we view the contents of the switches file we see the following:  

```
---
vlans:
  - 100
  - 200

ospf_processid: 1
...
```

The starting --- and ending ... mark this file as a YAML file.  We can see we have a variable called **vlans**, which is a list of 2 vlan numbers and a variable called **ospf_processid**.  These variables will apply to all devices in the group **switches**.


### Part 2: Ansible Playbooks & Templates

#### Ansible Playbook Taxonomy

In order to explore playbook structure, we will view the playbook titled [render_configurations.yaml](render_configurations.yaml). This playbook will generate a CLI configuration file based on variables and Jinja2 templates that we have defined.

```
# Playbook to show the final configuration rendered from Jinja2 Templates and host and group variables

#Specify Hosts and Connection Type to use
- hosts: switches
  connection: ansible.netcommon.network_cli

#Render Core and Access Templates for Devices and place them in the review_configs directory
  tasks:
    - name: Core Config Render
      when: inventory_hostname in groups['core']
      template:
        src: core_config.j2
        dest: "review_configs/{{ inventory_hostname }}.config"

    - name: Access Config Render
      when: inventory_hostname in groups['access']
      template:
        src: access_config.j2
        dest: "review_configs/{{ inventory_hostname }}.config"

```

