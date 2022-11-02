
## Ansible Lab Guide  -- Under Construction!!!

## Lab Table of Contents
* [Part 1: Ansible Setup Exploration](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide.md#part-1-ansible-setup-exploration)
* [Part 2: Ansible Playbooks & Templates](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part2.md#part-2-ansible-playbooks--templates)
* [Part 3: Using Ansible Playbooks to Deploy Configuration](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part3.md#part-3-using-ansible-playbooks-to-deploy-configuration)
* [Part 4:  Using pyATS parsers with Ansible](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part4.md#part-4--using-pyats-parsers-with-ansible)


### Part 2: Ansible Playbooks & Templates

#### Ansible Playbook Taxonomy

In order to explore playbook structure, we will view and run the playbook titled [ios_facts.yaml](Task_0_Fact_Finding/ios_facts.yaml). This playbook will connect to the devices in our inventory and collect data using the [cisco.ios.ios_facts](https://docs.ansible.com/ansible/latest/collections/cisco/ios/ios_facts_module.html#ansible-collections-cisco-ios-ios-facts-module) module.

The first section of the playbook contains the following:

**hosts**:  The hosts this playbook applies to.  Possible values here are a single host, a host group or all.  
**connection**: What type of connection should be used; See the [documentation](https://docs.ansible.com/ansible/latest/network/user_guide/platform_ios.html#connections-available) for more details.  For Cisco devices, ***ansible.netcommon.network_cli*** is used.  
**gather_facts**: A yes or no option that tells ansible whether to run the gather_facts module on the hosts.  Since this module is optimized for servers, we don't use it. Instead we will use the cisco.ios.ios_facts module. 

```

#Specify Hosts and Connection Type to use
- hosts: all
  connection: ansible.netcommon.network_cli
  gather_facts: no   
  
```  

The next section of the playbook includes the tasks to be run.  We have 2 tasks in this playbook.  The first task will use the cisco.ios.ios_facts module to gather information about our devices.  There are two different methods for noting which facts to gather:  the legacy gather_subset notation and the newer, gather_network_resources notation.  The newer notation is especially powerful because it returns structured data which can then be used directly to configure devices, ingested by scripts or just more easily parsed.  See the link in above to read further about the cisco.ios.ios_facts module.

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

This template begins with a **for loop**.  If you recall from our group_vars file [switches](group_vars/switches), we have a variable called vlans, which is a list of vlan numbers.  The for loop in our template will iterate through the list of vlans and run the commmand vlan \<number\> for each vlan in the list and then exit out of vlan config mode.  The variable notation in Jinja2 is the double curly brace ***{{ }}***  


```
{% for vlan in vlans%}
  vlan {{ vlan }}
{%endfor %}
exit
```
The next section will configure the access and trunk ports as defined in our [host_vars file](host_vars/10.1.#.15) for the access switch and some other configuration items that we need.  
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

The playbook **render_configurations.yaml** will take the configuration templates and values from the host and group vars we defined and generate the CLI configuration that will be pushed to the switches for us to review.  This step is not necessary as the config will be rendered on the fly by our configuration playbooks, but will allow us to get a preview of our complete configuration that will be pushed to the network devices prior to running the playbooks that will configure the switches.

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

There are 3 tasks that are very similar.  Each uses the [ansible.builtin.template](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html) module to render the configuration based on the specified Jinja2 template.

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

Roles can be installed by running `ansible-galaxy install role.name` for roles in [Ansible Galaxy](https://galaxy.ansible.com/), where collections and roles are published by vendors (including Cisco and most other major vendors) and the Ansible Community at large for use by anyone. A new role can be created with the proper directory structure by running `ansible-galaxy init mynewrole`.  Custom roles can also simply be copied into the roles directory.  As long as the roles directory can be found in the roles_path that we reviewed earlier as part of the ansible.cfg file, it can be used in your playbooks.

Roles can be referenced in a playbook using the **roles** option.  See this example from our playbook [get_switch_info_pyats_parsers.yaml](Task_0_Fact_Finding/get_switch_info_pyats_parsers.yaml):  

```
- hosts: switches
  connection: network_cli
  gather_facts: no
  roles:
    - ansible-pyats  
```
If we review our lab directory structure, we can see that there is a roles directory.  Within that roles directory there is a directory called **ansible-pyats**.   A deep dive into roles is beyond the scope of this session, but as you move further along in your Ansible journey, you may find that roles bring some highly beneficial re-use and modularity to your Ansible practice.  

[*On to Part 3: Using Ansible Playbooks to Deploy Configuration*](LabGuide_Part3.md)
