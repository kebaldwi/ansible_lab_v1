
## Ansible Lab Guide  -- Under Construction!!!

For how to access the lab, please go to [Lab Access Guide](LabAccess.md) for the details.

## Lab Table of Contents
* [Part 1: Ansible Setup Exploration](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide.md#part-1-ansible-setup-exploration)
* [Part 2: Ansible Playbooks & Templates](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part2.md#part-2-ansible-playbooks--templates)
* [Part 3: Using Ansible Playbooks to Deploy Configuration](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part3.md#part-3-using-ansible-playbooks-to-deploy-configuration)
* [Part 4:  Using pyATS parsers with Ansible](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part4.md#part-4--using-pyats-parsers-with-ansible)


### Part 1: Ansible Setup Exploration

#### Explore ansible.cfg file

We'll start by reviewing some of the important files for Ansible.  First we'll cover the ansible configuration file `ansible.cfg`, located in the ansible_lab_v1 directory. The ansible configuration file contains important Ansible settings that control how Ansible operates.  There are a few ways to identify the ansible configuration that will be used.  A simple way is to run the `ansible --version` command in the terminal. Here is an example of the output of that command:  

![json](./images/ansible_cfg.png?raw=true "Import JSON")  

See the [Ansible config documentation](https://docs.ansible.com/ansible/latest/reference_appendices/config.html) for more details.  There are many settings that can be adjusted based on the needs of your deployment.  

In our ansible.cfg, we are taking all defaults except for a few settings:

```
[defaults]
inventory = inventory_pod.ini
host_key_checking = False
roles_path=~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:/home/cisco/ansible_lab_v1/roles
```

1. Specifying the inventory file name.  By default, if an inventory file is not specified with the *ansible-playbook -i inventory-file_name* option, the inventory file name specified in the ansible.cfg file will be used.  We are modifying this setting to our inventory file name, inventory_pod.ini with this line:  
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

3. Defining our roles path.  This allows us the flexibility of telling ansible where our roles are installed so that they do not need to be in the same directory as our playbooks.  We will cover the definition and use of roles later in the lab.  
`roles_path=~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:/home/cisco/ansible_lab_v1/roles`

#### Explore the Inventory file

Let's take a look at the inventory file, **inventory_pod.ini** in the ansible_lab_v1 directory.  The inventory file can be in many formats, but is generally either in ini or YAML format.  See the [Ansible Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) on inventories.  Our Inventory file is in ini format. 

```
[access]  
10.1.#.15 

[core]  
10.1.#.14

[wan]  
10.1.#.13 

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

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 

### Action 1:  Complete the inventory  
  

Step 1:  Modify the **inventory_pod.ini** file and enter the correct IPs for the **access**, **core** and **wan** devices using your pod number.  For example, if you are in pod 4, your access switch ip will be **10.1.4.15**  
  
Step 2:  Complete the \[all:vars\] section in your inventory file.  Enter the values for **ansible_user**, **ansible_ssh_pass**, and **ansible_become_pass**.  

Don't forget to save your files after editing!  

NOTE:  If you get stuck, a completed example is in the Z_Final_Files folder in your working directory.  
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 

#### Explore Variable Files and Directories

There are many ways to define variables for use in our playbooks.  As we have just explored, we can define variables in our inventory files, but that can lead to complex and hard to manage inventory files.  Alternatively, we can also define them in our group_vars and host_vars directories and in our playbooks themselves.  Let's explore some of these other options.

#### Variables Directories

Let's explore our group_vars and host_vars directories:

```
├── group_vars
│   └── switches
├── host_vars
│   ├── 10.1.#.14
│   └── 10.1.#.15

```

In the group_vars directory we have a file called **switches**, which contains the variables that apply to the devices in the group **switches** as defined in our inventory file.

If we view the contents of the switches file we see the following:  

```
---
vlans:
  - 100
  - 200

ospf_processid: 1

telemetry_destination_ip: "10.1.#.19"
...
```

The starting --- and ending ... mark this file as a YAML file.  We can see we have a variable called **vlans**, which is a list of 2 vlan numbers, a variable called **ospf_processid**, and a third variable:  **telemetery_destination_ip**.  These variables will apply to all devices in the group **switches**.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 

### Action 2:  Modify the switches file in the group_vars directory  

 Modify the **switches** file and enter the correct IP for the **telemetry_destination_ip** using your pod number.  For example, if you are in pod 3, your value for **telemetry_destination_ip** will be "10.1.3.19"  

 Don't forget to save your file!  
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 

In the host_vars directory, we have 2 files.  Each file corresponds to a specific device defined in the inventory file.  This is where we define host-specific variables.  If we explore the file **10.1.#.15**, we see the following:

```
---
vlan100_interface: "GigabitEthernet1/0/1"
vlan200_interface: "GigabitEthernet1/0/2"
trunk_interface: "GigabitEthernet1/0/8"
...
```
The host that ends with **.15** is the access switch and we can see 3 variables defined.

You can also explore the **10.1.#.14** file, which maps to our core switch.  You can see many more variables defined in this file.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 
### Action 3:  Rename the files in the host_vars directory    

Step 1:  Rename the files in the host_vars directory to reflect the IPs in your pod.  For example if you are in pod 7, your files should be named 10.1.7.14 and 10.1.7.15.

You can accomplish by right-clicking the file name in VSCode and selecting **Rename** or in the terminal by entering the host_vars directory and using the **mv** command.  See this example:  

```
cd ~/ansible_lab_v1/host_vars
mv 10.1.#.14 10.1.7.14
mv 10.1.#.15 10.1.7.15
```  

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  

Now that you have explored the Ansible configuration, inventory and variable files, let's continue to Part 2 of the lab to explore Ansible Playbooks and Jinja2 Templates!

[*On to Part 2: Ansible Playbooks & Templates*](LabGuide_Part2.md)
