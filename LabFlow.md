
## Overall Lab Flow  -- Under Construction!!!


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
10.1.1.15 

[core]  
10.1.1.14

[router]  
10.1.1.13 

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
|  ├──10.1.1.14
|  └──10.1.1.15

```

In the group_vars folder we have a file called **switches**, which contains the variables that apply to the devices in the group **switches** as defined in our inventory file.

In the host_vars folder, we have 2 files.  Each file corresponds to a specific device defined in the inventory file.  So the file titled **10.1.1.14** contains variables that apply specifically to the host 10.1.1.14. 

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
  gather_facts: no
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
The first section of the playbook contains the following:

**hosts**:  The hosts should this playbook run against.  Possible values here are a single host, a host group or all.  
**gather_facts**: A yes or no switch that tells ansible whether to run the gather_facts module on the hosts.   
**connection**: What type of connection should be used See the [Documentation](https://docs.ansible.com/ansible/latest/network/user_guide/platform_ios.html#connections-available) for more details.  

```

#Specify Hosts and Connection Type to use
- hosts: switches
  gather_facts: no
  connection: ansible.netcommon.network_cli
  
```
The next section of the playbook includes the tasks to be run.  We have 2 tasks in this playbook.  Each of these tasks will use the template module in order to render CLI configuration for our devices based on the template defined as the source, the host group defined previously modified by the **when** statement,  and a destination for our rendered config using variables defined in the inventory file, group_vars, and host_vars files.  We will explore the templates themselves in the next section.

```
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

### Jinja2 Template Exploration

Jinja2 Templates are a dynamic way to apply standard configurations to multiple devices using variables.   To read more about using Jinja2 templates in Ansible, see the [documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html).  Templates are usually found in the [templates](templates) directory under our ansible playbook working directory.  Let's review the [access_config.j2](templates/access_config.j2) template.

The template begins with a **for loop**.  If you recall from our group_vars file [switches](group_vars/switches), we have a variable called vlans, which is a list of vlan numbers.  The for loop in our template will iterate through the list of vlans and run the commmand vlan \<number\> for each vlan in the list and then exit out of vlan config mode. 

```
{% for vlan in vlans%}
  vlan {{ vlan }}
{%endfor %}
exit
```
The next section will configure the access and trunk ports as defined in our [host_vars file for the access switch](host_vars/10.1.1.15) and some other configuration items that we need.

```
interface range GigabitEthernet1/0/1-8
  load-interval 30

interface {{ vlan100_interface }}
  no shut
  description configured by ansible
  switchport access vlan 100
  switchport mode access
  spanning-tree portfast

interface {{ vlan200_interface }}
  no shut
  description configured by ansible
  switchport access vlan 200
  spanning-tree portfast

interface {{ trunk_interface }}
  no shut
  description configured by ansible
  switchport mode trunk

interface range GigabitEthernet1/0/1-8
  load-interval 30

ip tcp mss 1280
ip http server
ip http secure-server
ip http client source-interface gigabitEthernet 0/0
ip http authentication local
gnxi server

event manager applet catchall
  event cli pattern ".*" sync no skip no
  action 1 syslog msg "$_cli_msg"

```
We can see what the final CLI configuration will be by running the playbook that we reviewed earlier: [render_configurations.yaml](render_configurations.yaml), which we will do further on in the lab guide.

### Ansible Roles 

Let's briefly touch on Ansible Roles.   Roles allow for the modularization and re-use of Ansible tasks, variables and other dependencies that can be loaded into a playbook.  See the documentation on [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html).  For our work today, we will be using the [ansible-pyats](https://github.com/CiscoDevNet/ansible-pyats) role so that we can make use of the pyats_parse_command module and genie_config_diff filter when running our configuration playbooks. 

Roles can be installed by running `ansible-galaxy install role.name` and a new role can be created with the correct directory structure by running `ansible-galaxy init mynewrole`

Roles can be referenced in a playbook using the **roles** keyword.  See this example from our playbook [get_switch_info_pyats_parsers.yaml](Task_0_Fact_Finding/get_switch_info_pyats_parsers.yaml):  

```
- hosts: switches
  connection: network_cli
  gather_facts: no
  roles:
    - ansible-pyats  
```

#### Quick Intro to pyATS and the ansible-pyats role

### Deploy Base Configuration to a site using Ansible Playbooks

### Deploy Model Driven Telemetry configurations to a site using Ansible Playbooks

### 
