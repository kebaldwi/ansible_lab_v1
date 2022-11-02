
## Ansible Lab Guide  -- Under Construction!!!

## Lab Table of Contents
* [Part 1: Ansible Setup Exploration](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part1.md#part-1-ansible-setup-exploration)
* [Part 2: Ansible Playbooks & Templates](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part2.md#part-2-ansible-playbooks--templates)
* [Part 3: Using Ansible Playbooks to Deploy Configuration](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part3.md#part-3-using-ansible-playbooks-to-deploy-configuration)
* [Part 4:  Using pyATS parsers with Ansible](https://github.com/chanhale/ansible_lab_v1/blob/master/LabGuide_Part4.md#part-4--using-pyats-parsers-with-ansible)

### Part 4:  Using pyATS parsers with Ansible

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
### Action 8:  Run the get_switch_info_pyats_parsers.yaml playbook  

Run the playbook and view the output.  There should be no failed tasks.  The playbook should run successfully and provide the information specified in the **Display Switch Info** task for both switches.

The output should look similar to this.  It's ok if it doesn't match exactly.  

![json](./images/get_switch_info_1.png?raw=true "Import JSON")  
![json](./images/get_switch_info_2.png?raw=true "Import JSON") 

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  

### Part 5: Finish up by deploying Model Driven Telemetry configurations to our access switch using Ansible Playbooks

In the next section, we will be exploring Model Driven Telemetry and using the TIG Stack in order to monitor our network devices.  We will use an ansible playbook with a Jinja2 template to deploy the MDT configuration to our access switch so that we will be able to review the telemetry in our Grafana dashboard later. 

Let's go ahead and run the [switch_MDT_config.yaml](Task_2_Apply_MDT_Configuration/switch_MDT_config.yaml) playbook


\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#   
### Action 9:  Run the switch_MDT_configuration.yaml playbook  

Step 1: Review the telemetry_config.j2 template in the templates directory.  We will go over what this config is doing later in the day.  Remember that you specified a value for the variable **telemetry_destination_ip** in the group_vars/switches variable file in the first section of the lab.  Feel free to review the switches variable file.

Step 2:  Review the switch_MDT_configuration.yaml playbook in the Task_2_Apply_MDT_Configuration directory.   You'll note this playbook is almost identical to the playbooks we ran to deploy the base configuration in earlier sections.   

Step 3:  Run the playbook with your preferred level of verbosity and view the output.  There should be no failed tasks.  The playbook should successfully add the telemetry configuration to the access switch.  Review the configuration lines added in the **Show Lines Added to Config** output.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#  

Congratulations! You have finished the Ansible Section of this lab! 

Stand by, we'll have a live discussion on Model-Driven Telemetry and the configuration we just deployed, Telegraf, Influxdb and the Grafana dashboard!! After the MDT introduction session, you will navigate to the [MDT Lab guide](MDTGuide.md) for a hands-on exploration of MDT.