
## Ansible Lab Guide  -- Under Construction!!!


### Part 1: Ansible Setup Exploration

#### Explore ansible.cfg file

We'll start by reviewing some of the important files for Ansible.  First we'll cover the ansible configuration file `ansible.cfg`. The ansible configuration file contains important Ansible settings that control how Ansible operates.  There are a few ways to identify the ansible configuration that will be used.  A simple way is to run the `ansible --version` command in the terminal. Here is an example of the output of that command:  

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

3. Defining our roles path.  This allows us the flexibility of telling ansible where our roles are installed so that they do not need to be in the same directory as our playbooks.
`roles_path=~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:/home/cisco/ansible_lab_v1/roles`

#### Explore the Inventory file

Let's take a look at the inventory file.  The inventory file can be in many formats, but is generally either in ini or YAML format.  See the [Ansible Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) on inventories.  Our Inventory file is in ini format. 

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

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 

#### Explore Variable Files and Directories

There are many ways to define variables for use in our playbooks.  As we have just explored, we can define variables in our inventory files, but that can lead to complex and hard to manage inventory files.  Alternatively, we can also define them in our group_vars and host_vars directories and in our playbooks themselves.  Let's explore some of these other options.

#### Variables Directories

Let's explore our group_vars and host_vars directories:

```
├──group_vars
|  └──switches
├──host_vars
|  ├──10.1.#.14
|  └──10.1.#.15

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
### Action 3:  Rename the files in the host_vars directory and edit the hostname variables    

Step 1:  Rename the files in the host_vars directory to reflect the IPs in your pod.  For example if you are in pod 7, your files should be named 10.1.7.14 and 10.1.7.15.

You can accomplish by right-clicking the file name in VSCode and selecting **Rename** or in the terminal by entering the host_vars directory and using the mv command.  See this example:  

```
cd ~/ansible_lab_v1/host_vars
mv 10.1.#.14 10.1.7.14
mv 10.1.#.15 10.1.7.15
```  

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  

### Part 2: Ansible Playbooks & Templates

#### Ansible Playbook Taxonomy

In order to explore playbook structure, we will view and run the playbook titled [ios_facts.yaml](Task_0_Fact_Finding/ios_facts.yaml). This playbook will connect to the devices in our inventory and collect data using the [cisco.ios.ios_facts](https://docs.ansible.com/ansible/latest/collections/cisco/ios/ios_facts_module.html#ansible-collections-cisco-ios-ios-facts-module) module.

The first section of the playbook contains the following:

**hosts**:  The hosts this playbook applies to.  Possible values here are a single host, a host group or all.  
**connection**: What type of connection should be used See the [documentation](https://docs.ansible.com/ansible/latest/network/user_guide/platform_ios.html#connections-available) for more details.  For Cisco devices, ***ansible.netcommon.network_cli*** is used.  
**gather_facts**: A yes or no option that tells ansible whether to run the gather_facts module on the hosts.  Since this module is optimized for servers, we don't use it. Instead we will use the cisco.ios.ios_facts module. 

```

#Specify Hosts and Connection Type to use
- hosts: all
  connection: ansible.netcommon.network_cli
  gather_facts: no   
  
```  

The next section of the playbook includes the tasks to be run.  We have 2 tasks in this playbook.  The first task will use the cisco.ios.ios_facts module to gather information about our devices.  There are two different methods for noting which facts to gather:  the legacy gather_subset notation and the newer, gather_network_resources notation.  The newer notation is especially powerful because it returns structured data which can then be used directly to configure devices, ingested by scripts or just more easily parsed.  See the link above to read further about the cisco.ios.ios_facts module.

The second task uses the debug module to display a message containing some of the information we've gathered.  

```
  tasks:
    - name: Get IOS Facts
      cisco.ios.ios_facts:
        gather_subset: min
        gather_network_resources: interfaces

    - name: Display Device Info
      debug:
        msg:
          - "Hostname: {{ ansible_net_hostname }}"
          - "Serial Number: {{ ansible_net_serialnum }}"
          - "IOS-XE Version: {{ ansible_net_version }}"
          - "Model: {{ ansible_net_model }}"
          - "Interfaces {{ ansible_network_resources['interfaces'] }}"
```

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 
### Action 4:  Run the ios_facts.yaml playbook  

Run the playbook in the VSCode Terminal

```
cd ~/ansible_lab_v1/
ansible-playbook -i inventory_pod.ini Task_0_Fact_Finding/ios_facts.yaml
```  
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 

The output should look similar to this, but it is ok if the exact details of the output are different:

![json](./images/ios_facts_screen_1.png?raw=true "Import JSON")  
![json](./images/ios_facts_screen_2.png?raw=true "Import JSON")  

As we can see, we've quickly and easily collected some valuable information about our devices.  We have hostnames, serial numbers, code versions and model numbers. This also verifies that we are able to connect to our network devices and our inventory file is correctly configured.

Next we will move on to exploring Jinja2 Templates and configuring our network devices using Ansible Playbooks.

### Jinja2 Template Exploration

Jinja2 Templates are a dynamic way to apply standard configurations to multiple devices using variables.   To read more about using Jinja2 templates in Ansible, see the [documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html).  Templates are usually found in the [templates](templates) directory under our ansible playbook working directory.  Let's review the [access_config.j2](templates/access_config.j2) template, which as the name suggests, is the template for our access switch.

This template begins with a **for loop**.  If you recall from our group_vars file [switches](group_vars/switches), we have a variable called vlans, which is a list of vlan numbers.  The for loop in our template will iterate through the list of vlans and run the commmand vlan \<number\> for each vlan in the list and then exit out of vlan config mode.

```
{% for vlan in vlans%}
  vlan {{ vlan }}
{%endfor %}
exit
```
The next section will configure the access and trunk ports as defined in our [host_vars file](host_vars/10.1.#.15) for the access switch and some other configuration items that we need.  The variable notation in Jinja2 is the double curly brace ***{{ }}***

```

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

event manager applet catchall
  event cli pattern ".*" sync no skip no
  action 1 syslog msg "$_cli_msg"

```
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#   
NOTE:  A great resource for learning more about Jinja2 Templating is [Przemek Rogala's Blog Series](https://ttl255.com/jinja2-tutorial-part-1-introduction-and-variable-substitution/) on the subject.  
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\# 

We can see what the final CLI configuration will be by running the playbook: [render_configurations.yaml](render_configurations.yaml).

The playbook render_configurations.yaml will take the configuration templates and values from the host and group vars we defined and generate the CLI configuration that will pushed to the switches for us to review.  This step is not necessary as the config will be rendered on the fly by our configuration playbooks, but will allow us to get a preview of our complete configuration that will be pushed to the network devices prior to running the playbooks that will configure the switches.

Let's take a look at [render_configurations.yaml](render_configurations.yaml).

```
# Playbook to show the final configuration rendered from Jinja2 Templates and host and group variables

#Specify Hosts and Connection Type to use
- hosts: switches
  gather_facts: no
  connection: ansible.netcommon.network_cli

  tasks:
    - name: Core Config Render
      when: inventory_hostname in groups['core']
      ansible.builtin.template:
        src: "~/ansible_lab_v1/templates/core_config.j2"
        dest: "~/ansible_lab_v1/review_configs/{{ inventory_hostname }}.config"

    - name: Access Config Render
      when: inventory_hostname in groups['access']
      ansible.builtin.template:
        src: "~/ansible_lab_v1/templates/access_config.j2"
        dest: "~/ansible_lab_v1/review_configs/{{ inventory_hostname }}.config"

    - name: MDT Config Render
      when: inventory_hostname in groups['access']
      ansible.builtin.template:
        src: "~/ansible_lab_v1/templates/telemetry_config.j2"
        dest: "~/ansible_lab_v1/review_configs/{{ inventory_hostname }}_MDT.config"
```

Let's focus on the tasks section of the playbook.

There are 3 tasks that are very similar.  Each uses the [ansible.builtin.template](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html) module to render configuration based on the specified Jinja2 template.

The first task, named Core Config Render, will render a config based on the template called [core_config.j2](templates/core_config.j2).  The rendered configuration will be written to a file named after the host in the review_configs directory, such that the host 10.1.6.14, will result in a file called **10.1.6.14.config**.  There is a new parameter in this task that we haven't seen before:  **when**.    

The **when** parameter allows us to add a condition for when this task will run.  In this case, we only want to render the Core configuration for hosts in the group **core**.  **When** allows us to specify a comprehensive host group for the playbook while still limiting each task to only the hosts to which it should apply.  Host group is only one of the conditions that can be used in a when statement.

```
    - name: Core Config Render
      when: inventory_hostname in groups['core']
      ansible.builtin.template:
        src: "~/ansible_lab_v1/templates/core_config.j2"
        dest: "~/ansible_lab_v1/review_configs/{{ inventory_hostname }}.config"
```   

The next two tasks do the same for the access switch group.  The first task renders the base config using the [access_config.j2](templates/access_config.j2) template, and the final task renders the [telemetry_config.j2](templates/telemetry_config.j2) template into the Model Driven Telemetry configuration we will need later in the lab.

```
    - name: Access Config Render
      when: inventory_hostname in groups['access']
      ansible.builtin.template:
        src: "~/ansible_lab_v1/templates/access_config.j2"
        dest: "~/ansible_lab_v1/review_configs/{{ inventory_hostname }}.config"

    - name: MDT Config Render
      when: inventory_hostname in groups['access']
      ansible.builtin.template:
        src: "~/ansible_lab_v1/templates/telemetry_config.j2"
        dest: "~/ansible_lab_v1/review_configs/{{ inventory_hostname }}_MDT.config"

```   

Now that we have reviewed the render_configurations.yaml playbook, we can run it.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  
### Action 5:  Run the render_configurations.yaml playbook  

Run the playbook in the VSCode Terminal

```
cd ~/ansible_lab_v1/
ansible-playbook -i inventory_pod.ini Task_0_Fact_Finding/render_configurations.yaml
```  
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#   

After a successful run of this playbook, we should see three new files in the review_configs directory.  Take a moment to review the rendered configurations.  As you can see, variables defined in the Jinja2 template have been replaced with values from both the host_vars and group_vars files.  

Now we are almost ready to review and run our configuration playbooks, but before that, let's briefly review the concept of Ansible Roles.  

### Ansible Roles 

Ansible Roles allow for the modularization and re-use of Ansible tasks, variables, handlers and other dependencies that can be loaded into a playbook.  See the documentation on [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html).  For our work today, we will be using the [ansible-pyats](https://github.com/CiscoDevNet/ansible-pyats) role so that we can make use of the pyats_parse_command module and genie_config_diff filter when running our configuration playbooks.  

pyATS is a powerful framework for automated testing and the de-facto test framework for internal Cisco Engineers.  For a more comprehensive introduction to pyATS, see the [Cisco pyATS Documentation](https://developer.cisco.com/docs/pyats/).  pyATS is not limited to use with Ansible and can be a fantastic way to run automated tests on your network or lab as part of a CI/CD Pipeline or to just make change validation faster and more automated.  A deep dive into pyATS is outside the scope of this workshop, but please explore the documentation linked above to learn more!

Roles can be installed by running `ansible-galaxy install role.name` for roles in [Ansible Galaxy](https://galaxy.ansible.com/), where collections and roles are published for use by vendors (including Cisco and most other major vendors) and the Ansible Community at large. A new role can be created with the proper directory structure by running `ansible-galaxy init mynewrole`.  Custom roles can also simply be copied into the roles directory.  As long as the roles directory can be found in the roles_path that we reviewed earlier as part of the ansible.cfg file, it can be used in your playbooks.

Roles can be referenced in a playbook using the **roles** option.  See this example from our playbook [get_switch_info_pyats_parsers.yaml](Task_0_Fact_Finding/get_switch_info_pyats_parsers.yaml):  

```
- hosts: switches
  connection: network_cli
  gather_facts: no
  roles:
    - ansible-pyats  
```
If we review our lab directory structure, we can see that there is a roles directory.  Within that roles directory there is a directory called **ansible-pyats**.   A deep dive into roles is beyond the scope of this session, but as you move further along in your Ansible journey, you may find that roles bring some highly beneficial re-use and modularity to your Ansible practice.  

### Part 3: Using Ansible Playbooks to Apply Configuration

In this section of the lab, we will deploy a base configuration to our topology.  Let's briefly review the topology

![json](./images/pod_diagram.png?raw=true "Import JSON")  

We'll use Ansible playbooks to push the base configuration templates to the core and access switch and make a configuration change to the wan router.    

Let's review the [core_switch_base_config.yaml](./Task_1_Apply_Base_Configuration/core_switch_base_config.yaml) playbook

```
- hosts: core
  gather_facts: no
  connection: ansible.netcommon.network_cli
  roles:
    - ansible-pyats

#Specify Tasks to perform
  tasks:
    - name: Prerun Config Collection
      cisco.ios.ios_command: 
        commands: show run
      register: prior_config

    - name: Apply Initial Configuration
      cisco.ios.ios_config:
        src: "~/ansible_lab_v1/templates/core_config.j2"
        save_when: changed

    - name: Post-Run Config Collection
      cisco.ios.ios_command: 
        commands: show run
      register: post_config
    
    - name: Show Lines Added to Config
      debug:
        msg: "{{ prior_config.stdout[0] | genie_config_diff(post_config.stdout[0], mode='add', exclude=exclude_list) }}"

  vars:
    exclude_list:
      - (^Using.*)
      - (Building.*)
      - (Current.*)
      - (crypto pki certificate chain.*)
```
At the start of the playbook we see familiar statements that we can interpret to mean this playbook will run on devices in the group **core** using the ansible.netcommon.network_cli connection method and that we do not want to run the gather_facts module on our devices.

The first task contains a module we haven't seen before:  **cisco.ios.ios_command**.  The [cisco.ios.ios_command](https://docs.ansible.com/ansible/latest/collections/cisco/ios/ios_command_module.html) module executes a command or list of commands on a cisco device.  Note, the **cisco.ios.ios_command** module isn't used to make configuration changes on network devices.  

In this case, we're using the module to execute a show run on the device and get back the output.  Note that there are a number of different ways to get the configuration from a device, you may have come across other options during your Ansible practice.  

The next new item is the **register** parameter.  This simply tells Ansible to save the result of the task to a variable that is, in this case, called **prior_config** and can be referenced later.

```
    - name: Prerun Config Collection
      cisco.ios.ios_command: 
        commands: show run
      register: prior_config

```
The second task is where we actually deploy our configuration template to our network device using [cisco.ios.ios_config](https://docs.ansible.com/ansible/latest/collections/cisco/ios/ios_config_module.html).  As the name implies, the cisco.ios.ios_config module is used to modify the configuration on a Cisco IOS/IOS-XE device.  Note that the **src** parameter allows us to reference the previously discussed Jinja2 template which contains the configuration we want to send.  

The cisco.ios.ios_config module is powerful and flexible.  The usage here is only one way of sending configuration to network devices.  Please review the documentation linked above for more options and examples.  

The final parameter in the task is **save_when**.  This parameter controls under what circumstances the task will save the running-config, the option **changed** will only do so if the task results in a change to the running configuration, other options can be explored in the documentation.

```
    - name: Apply Initial Configuration
      cisco.ios.ios_config:
        src: "~/ansible_lab_v1/templates/core_config.j2"
        save_when: changed
```

The final two tasks in this playbook, in conjunction with the first task, will allow us to see exactly what was changed by our configuration task.   First, we collect the running config again using a repeat of task 1:  

```
    - name: Post-Run Config Collection
      cisco.ios.ios_command: 
        commands: show run
      register: post_config
```

Then we make use of the **debug** module as referenced earlier to display information on our configuration change.  To provide more detail, the task, **Show Lines Added to Config**, uses the filter **genie_config_diff** to compare the running config taken prior to the configuration change to the post-change configuration.  The option `mode='add'` limits the output to lines added to the config (meaning we ignore any lines that were removed) and the `exclude=exclude_list` option will ignore any diffs in configuration that match the **exclude_list** specified in the **vars** section at the bottom of the playbook.  This is done to limit irrelevant output or config lines that might have changed simply based on the time difference between when the two tasks were run.

```
    - name: Show Lines Added to Config
      debug:
        msg: "{{ prior_config.stdout[0] | genie_config_diff(post_config.stdout[0], mode='add', exclude=exclude_list) }}"

  vars:
    exclude_list:
      - (^Using.*)
      - (Building.*)
      - (Current.*)
      - (crypto pki certificate chain.*)

```
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  
### Action 6:  Run the core_switch_base_config.yaml playbook  

Run the playbook in the VSCode Terminal

```
cd ~/ansible_lab_v1/
ansible-playbook -i inventory_pod.ini Task_1_Apply_Base_Configuration/core_switch_base_config.yaml
```  
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

The output should look similar to this. It is ok if the exact details of the output are different, but you should see a number of lines added to the config and a successful completion of the playbook with no failed tasks:  

![json](./images/core_switch_base_config_1.png?raw=true "Import JSON")  
![json](./images/core_switch_base_config_2.png?raw=true "Import JSON")  

In order to complete the provisioning of our site, we need to configure the access switch.   The playbook created for this purpose is [access_switch_base_config.yaml](./Task_1_Apply_Base_Configuration/access_switch_base_config.yaml), but it is not complete.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  
### Action 6:  Complete and Run the access_switch_base_config.yaml playbook  

This playbook, located in the Task_1_Apply_Base_Config directory, is missing a number of parameters.  Using your learning from previous sections, replace the comments with the missing parameters and run the playbook.

```
# Deploy base config to access switch and use genie parser to show diffs in debug

#Specify Host Group to use
- hosts: #Enter the appropriate host group             <--- Enter the correct host group
  gather_facts: no
  connection: #Enter the connection type
  roles:
    - ansible-pyats

#Specify Tasks to perform
  tasks:
    - name: Prerun Config Collection
      cisco.ios.ios_command: 
        commands: show run
      #Enter the parameter that will save the output to a variable called "prior_config"   <---  Enter the parameter

    - name: Apply Initial Configuration
      cisco.ios.ios_config:
        src: "~/ansible_lab_v1/templates/access_config.j2"
        save_when: #Enter the correct option to save the configuration when this task modifies the config   <--- Enter the option

    - name: Post-Run Config Collection
      cisco.ios.ios_command: 
        commands: show run
      #Enter the parameter that will save the output to a variable called "post_config"  <---  Enter the parameter
    
    - name: Show Lines Added to Config
      #Enter the module name to print the output.  <--- Enter the parameter
        msg: "{{ prior_config.stdout[0] | genie_config_diff(post_config.stdout[0], mode='add', exclude=exclude_list) }}"

  vars:
    exclude_list:
      - (^Using.*)
      - (Building.*)
      - (Current.*)
      - (crypto pki certificate chain.*)






```




Open the file in VSCode by clicking on it.

Hint:  Review the core_switch_base_config.yaml for reference if needed.

Run the playbook in the VSCode Terminal

```
cd ~/ansible_lab_v1/
ansible-playbook -i inventory_pod.ini Task_1_Apply_Base_Configuration/access_switch_base_config.yaml
```  
  
Verification:
If your playbook has run correctly, The site should have full connectivity and client1 and client2 should be able to reach server1.  

To test this:

1. Open the Chrome Browser from your jumphost.  
2. Click on the client1-vnc bookmark in the bookmarks bar.  
![json](./images/client1vnc_bookmark.png?raw=true "Import JSON") 
3. Once the VNC window opens, open the Firefox Browser in the VNC window.  
![json](./images/firefox.png?raw=true "Import JSON")  
4. Once the Firefox Browser opens, click on the server1 bookmark in the bookmarks bar.  
![json](./images/server1_bookmark.png?raw=true "Import JSON")
  
Wait a minute or so and if you are successful, you'll see a cool message from a mysterious guy!  Let your proctor know who you saw!

NOTE:  If you get stuck, the completed playbook is in the Final_Files folder in your working directory.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

You have applied a base config to your site and established end-to-end connectivity!  On to the next section!

### Part 3: A Quick look at Network Resource Modules and running playbooks with Verbose Options

Ansible [Network Resource Modules](https://docs.ansible.com/ansible/latest/network/user_guide/network_resource_modules.html) allow you to configure subsections of the configuration in a structured way.   To see a list of avaiable network resource modules for Cisco IOS/IOS-XE devices see the [cisco.ios](https://docs.ansible.com/ansible/latest/collections/cisco/ios/index.html) module documentation. 

Ansible network resource modules provide some really good benefits, Such as:
- gather_network_resources returns facts in a structured data format that can be directly used by network resource modules to configure devices,  and there is a corresponding gather subset for every network resource module    
- Different vendors' network resource modules use the same structure/syntax for the same network resources  
- Better options for **state** keys   
- More intuitive and logical structure for configuration with nested structures where it makes sense  

The only drawback of network resource modules is the limited number of them availble.  There aren't network resource modules for every configuration that you might need to manage.  

In order to get a little bit of exposure to network resource modules, we will use a simple playbook that calls the [cisco.ios.ios_hostname](https://docs.ansible.com/ansible/latest/collections/cisco/ios/ios_hostname_module.html) network resource module to change the hostname of our C8kv router.See the playbook titled [router_hostname.yaml](Task_1.5_Day_N_Config_Change/router_hostname.yaml):

```
# Modify Hostname on WAN Router

- hosts: wan
  connection: ansible.netcommon.network_cli
  gather_facts: no
    
  tasks:
    - name: Modify Router Hostname
      cisco.ios.ios_hostname:
        config:
          hostname: # Enter hostname as wan-pod#
        state: replaced  

```

This playbook is very straightforward.  We are using cisco.ios.ios_hostname to modify the hostname on the router.  The only new syntax to highlight here is the final line `state: replaced`.  There are a number of different state options, such as `merged`, which, while not useful for a this hostname module, is used when we just want to add our config to what already exists on the device, or `overridden`, which is a dangerous option that removes all configuration under the purview of the network resource module and replaces it with what is specified in the task.   

Consider a resource module for l3 interfaces, `overridden` would remove all l3 interface configuration from all l3 interfaces and then configure what is specified in the task, whereas `replaced` simply replaces the exact configuration specified in the task.  Review the documentation for more detail on states.


Let's also take the time to explore running an ansible playbook in **verbose** mode.  By adding a command line option we can see more and more information.  From a little bit of extra information with **-v** up to debug-level information with **-vvvv**.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  
### Action 7:  Run the router_hostname.yaml playbook  

Step 1:  Modify the playbook with a new hostname for the router.  Use your pod number. For example, if you are in pod 1, your new hostname would be wan-1.  Don't forget to save after modifying your playbook.

Step 2:  Run the playbook with different verbosity options to see what is returned.  Due to the Idempotency of the resource module, only your first run should result in a change to the configuration on the router.

```

cd ~/ansible_lab_v1/
ansible-playbook -i inventory_pod.ini Task_1.5_Day_N_Config_Change/router_hostname.yaml -v
ansible-playbook -i inventory_pod.ini Task_1.5_Day_N_Config_Change/router_hostname.yaml -vv
ansible-playbook -i inventory_pod.ini Task_1.5_Day_N_Config_Change/router_hostname.yaml -vvv
ansible-playbook -i inventory_pod.ini Task_1.5_Day_N_Config_Change/router_hostname.yaml -vvvv
```  

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

### Part 4: Finish up by deploying Model Driven Telemetry configurations to our access switch using Ansible Playbooks

Later in the day, we will be exploring Model Driven Telemetry and using the TIG Stack in order to monitor our network devices.  We will use ansible playbooks and a Jinja2 template to deploy the MDT configuration to our access switch so that we will be able to review the telemetry in our Grafana dashboard later. 

Let's go ahead and run the [switch_MDT_config.yaml](Task_2_Apply_MDT_Configuration/switch_MDT_config.yaml) playbook


\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  

### Action 8:  Run the switch_MDT_configuration.yaml playbook  

Step 1: Review the telemetry_config.j2 template in the templates directory.  We will go over what this config is doing later in the day.  Remember that you specified a value for the variable **telemetry_destination_ip** in the group_vars/switches variable file in the first section of the lab.  Feel free to review the switches variable file.

Step 2:  Review the switch_MDT_configuration.yaml playbook in the Task_2_Apply_MDT_Configuration directory.   You'll note this playbook is almost identical to the playbooks we ran to deploy the base configuration in earlier sections.   

Step 3:  Run the playbook with your preferred level of verbosity and view the output.  There should be no failed tasks.  The playbook should successfully add the telemetry configuration to the access switch.  Review the configuration lines added in the **Show Lines Added to Config** output.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

Next, let's take a look at using pyATS parsers to glean information from our network devices.   The Ansible module cisco.ios.ios_facts can provide structured data for a subset of network resource modules, but what if you want to collect some data in a structured format that doesn't currently have a network resource module?

This is where pyATS & Genie can help!  pyATS/Genie supports structured parsers for [hundreds](https://pubhub.devnetcloud.com/media/genie-feature-browser/docs/#/parsers) of IOS/IOS-XE show commands, with more being added often!  This allows you to get predictable, structured data from your devices that can be used in your playbooks or with native pyATS & Genie.

Let's explore this by reviewing the playbook [get_switch_info_pyats_parsers.yaml](Task_0_Fact_Finding/get_switch_info_pyats_parsers.yaml).

```
# use pyATS parsers to get structured data back from devices and display in debug

- hosts: switches
  connection: network_cli
  gather_facts: no
  roles:
    - ansible-pyats
    
  tasks:
    - name: Get Version Info
      pyats_parse_command:
        command: show version
      register: version_output

    - name: Get VLAN Info
      pyats_parse_command:
        command: show vlan summary
      register: vlan_output

    - name: Get Trunk Info
      pyats_parse_command:
        command: show interface trunk
      register: trunk_output 

    - name: Display Switch Info
      debug:
        msg:
          - "Hostname: {{ version_output.structured.version.hostname }}"
          - "Serial Number: {{ version_output.structured.version.chassis_sn }}"
          - "IOS-XE Version: {{ version_output.structured.version.version }}"
          - "Config Register: {{ version_output.structured.version.curr_config_register }}"
          - "Uptime: {{ version_output.structured.version.uptime }}"
          - "Number of VLANs: {{ vlan_output.structured.vlan_summary.existing_vlans }}"
          - "License Information: {{ version_output.structured | json_query('version.license_package.[*][0][0].license_level') }} {{ version_output.structured | json_query('version.license_package.[*][0][1].license_level') }}"
          - "Trunk and Active Vlans {{ trunk_output.structured | json_query('interface.[*][0][0].name') }}  {{ trunk_output.structured | json_query('interface.[*][0][0].vlans_allowed_active_in_mgmt_domain') }}"
```

At the start of the playbook, you can see the [ansible-pyats](https://github.com/CiscoDevNet/ansible-pyats) role being called.  We covered roles and the ansible-pyats role in a previous section.

```
- hosts: switches
  connection: network_cli
  gather_facts: no
  roles:
    - ansible-pyats
```

 In the tasks section you can see a number of **pyats_parse_command** tasks that register their output to variables.  The **pyats_parse_command** module takes an argument of a ios/ios-xe command and uses the parser library to convert the output returned from the devices into a structured data format that is documented in the parser library linked above.

 ```
   tasks:
    - name: Get Version Info
      pyats_parse_command:
        command: show version
      register: version_output

    - name: Get VLAN Info
      pyats_parse_command:
        command: show vlan summary
      register: vlan_output

    - name: Get Trunk Info
      pyats_parse_command:
        command: show interface trunk
      register: trunk_output 
 ```

 And finally we see a debug task that outputs data:  

 ```
    - name: Display Switch Info
      debug:
        msg:
          - "Hostname: {{ version_output.structured.version.hostname }}"
          - "Serial Number: {{ version_output.structured.version.chassis_sn }}"
          - "IOS-XE Version: {{ version_output.structured.version.version }}"
          - "Config Register: {{ version_output.structured.version.curr_config_register }}"
          - "Uptime: {{ version_output.structured.version.uptime }}"
          - "Number of VLANs: {{ vlan_output.structured.vlan_summary.existing_vlans }}"
          - "License Information: {{ version_output.structured | json_query('version.license_package.[*][0][0].license_level') }} {{ version_output.structured | json_query('version.license_package.[*][0][1].license_level') }}"
          - "Trunk and Active Vlans {{ trunk_output.structured | json_query('interface.[*][0][0].name') }}  {{ trunk_output.structured | json_query('interface.[*][0][0].vlans_allowed_active_in_mgmt_domain') }}"

 ```
These data structures might look a bit intimidating, but because we know what the structure of the returned data will be, it is straightforward to access the exact data points that we need. We can also use the [ansible.builtin.copy](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html) module or similar to write our data out to a CSV file and have a custom inventory from our install base readily available to ingest into other systems or provide to auditors or managers.  Go ahead and run this playbook.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  
### Action 9:  Run the get_switch_info_pyats_parsers.yaml playbook  

Run the playbook and view the output.  There should be no failed tasks.  The playbook should run successfully and provide the information specified in the **Display Switch Info** task for both switches.

The output should look similar to this.  It's ok if it doesn't match exactly.  

![json](./images/get_switch_info_1.png?raw=true "Import JSON")  
![json](./images/get_switch_info_2.png?raw=true "Import JSON") 

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

Congratulations! You have finished the Ansible Section of this lab!  Next, let's explore MDT, the TIG stack and the Grafana dashboard!!

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

### Part 5: Explore MDT config with switch and TIG stack

Now you have switches and router all configured through ansible. Well done! At this moment, telemetry has been collected through telegraf. Telegraf, data collector, outputs the data into influxDB, time series database. Then grafana visualizes the telemetry data in dashboard. In this lab, we have telegraf, influxDB, and grafana all configured already. There is no configuration change needed in this section. We will go through switch configuration, telegraf configuration, and grafana to explain how they are all tied together. Here is high level flow how the telemetry is collected through the TIG stack.

![json](./images/tig.png?raw=true "Import JSON")

There are three ways we use to collect the telemetry from the switches. For access switch, we mainly use gRPC dial-out method. You have used ansible playbook in the last section to configure the access switch to send telemetry to telegraf. For core switch, we use gNMI dial-in method. The core switch itself only has two commands required. Most of configuration specifying the yang xpath is done through telegraf configuration.


