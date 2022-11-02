
## Ansible Lab Guide  -- Under Construction!!!

## Lab Table of Contents
* [Part 1: Ansible Setup Exploration](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part1.md#part-1-ansible-setup-exploration)
* [Part 2: Ansible Playbooks & Templates](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part2.md#part-2-ansible-playbooks--templates)
* [Part 3: Using Ansible Playbooks to Deploy Configuration](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part3.md#part-3-using-ansible-playbooks-to-deploy-configuration)
* [Part 4:  Using pyATS parsers with Ansible](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part4.md#part-4--using-pyats-parsers-with-ansible)

### Part 3: Using Ansible Playbooks to Deploy Configuration

In this section of the lab, we will deploy a base configuration to our topology.  Let's briefly review the topology

![json](./images/pod_diagram.png?raw=true "Import JSON")  

We'll use Ansible playbooks to push the configuration templates to the core and access switch and make a configuration change to the wan router.      

Let's review the [core_switch_base_config.yaml](./Task_1_Apply_Base_Configuration/core_switch_base_config.yaml) playbook:  

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
The second task deploys our configuration template to our network device using [cisco.ios.ios_config](https://docs.ansible.com/ansible/latest/collections/cisco/ios/ios_config_module.html).  As the name implies, the cisco.ios.ios_config module is used to modify the configuration on a Cisco IOS/IOS-XE device.  Note that the **src** parameter allows us to reference the previously discussed Jinja2 template which contains the configuration we want to send.  

The cisco.ios.ios_config module is powerful and flexible.  The usage here is only one way of deploying configuration to network devices.  Please review the documentation linked above for more options and examples.  

The final parameter in the task is **save_when**.  This parameter controls under what circumstances the task will save the running-config, the option **changed** will only do so if the task itself results in a change to the running configuration, other options can be explored in the documentation.

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

Then we make use of the **debug** module as referenced earlier to display information on our configuration change.  To provide more detail, the task, **Show Lines Added to Config**, uses the filter **genie_config_diff** to compare the running config taken prior to the configuration change to the post-change configuration.  The option `mode='add'` limits the output to lines added to the config (meaning we ignore any lines that were removed) and the `exclude=exclude_list` option will ignore any diffs in the configuration that match the **exclude_list** specified in the **vars** section at the bottom of the playbook.  This is done to limit irrelevant output or config lines that might have changed simply based on the time difference between when the two tasks were run.

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

NOTE:  If you get stuck, the completed playbook is in the Z_Final_Files folder in your working directory.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

You have applied a base config to your switches and established end-to-end connectivity!  

### A Quick look at Network Resource Modules and running playbooks with Verbose Options

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
  
   
NOTE:  If you get stuck, a completed example is in the Z_Final_Files folder in your working directory.  
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

Congratulations, you have learned about verbose options and used Ansible network resource modules to configure your router!

[*On to Part 4: Using pyATS parsers with Ansible](LabGuide_Part4.md)

