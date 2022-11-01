## MDT Lab Guide

You have finished configuring your switches and router using Ansible. Well done! At this moment, telemetry is being collected from your network infrastructre through Telegraf. Telegraf, a data collector, outputs the data into InfluxDB, a time series database. Then Grafana visualizes the telemetry data in a custom dashboard. In this lab, we have already configured Telegraf, InfluxDB, and Grafana. There is no configuration change needed in this section. We will go through the switch configuration, Telegraf configuration, and Grafana to explain how they all tie together. Here is high level flow of how the telemetry is collected through the TIG stack.

![json](./images/tig.png?raw=true "Import JSON")

There are several roles in Model Driven Telemetry.
* Publisher: Network element that sends the telemetry data. In our lab, these are the switches.
* Receiver: This is also called a collector. It receives the telemetry data. In our lab, this is Telegraf.
* Controller: Network element that creates subscriptions but does not receive the telemetry data. In our lab, this is the switch.
* Subscriber: Network element that creates subscriptions. In our lab, Telegraf is the subscriber for gNMI implementation to subscribe to the switch telemetry data.

Telegraf plays a critical role in our lab since it collects all the telemetry data through gRPC/gNMI/SNMP and normalizes them before it writes to the InfluxDB database. InfluxDB in our lab doesn't have much customized configuration after the initialization of database. Grafana uses different types of queries to InfluxDB to fetch the telemetry for dashboard visualization. 

There are three methods we use to collect the telemetry from the switches. 
* gRPC: We use the gRPC dial-out method on the "access" switch. You have executed an Ansible playbook in the last section of the lab to configure the access switch to send telemetry to Telegraf. 
* gNMI: We use the gNMI dial-in method on the "core" switch. Most of the gNMI configuration specifying the YANG xpath is done through Telegraf. If you compare the gNMI configuration to the gRPC configuration, we move all the xpath specifications from the switch side to the Telegraf side.
* SNMP: We also use SNMP in this lab to pull the product ID (PID) and interface operational status on the "access" switch. This will show you how flexible the TIG stack is to support mixed types of telemetry.

In the next sections, we will go through the switch, Telegraf, influxDB, and Grafana configurations individually.

### Switch Configuration On Telemetry
Model Driven Telemetry configuration on the switch needs several key prerequisites.
* YANG. Since all data is stored in a database, we will need to enable the access to this database in the switch from the collector (Telegraf). The **netconf-yang** command needs to be configured on the device for telemetry to work.
* XML Xpath. XPath is XML Path Language. This specifies where the telemetry data is. 
* The _urn:ietf:params:netconf:capability:notification:1.1_ capability must be listed in hello messages. This capability is advertised only on devices that support IETF telemetry.

There are two useful commands to validate the prerequisites:
```
show platform software yang-management process
```
You can ssh to "core" or "access" switch and run this command above. The output should be like below. All processes should be in "running" state.

![json](./images/core_show_process.png?raw=true "Import JSON")

Another command is to validate the capability prerequisite mentioned above. Execute this command in your Visual Code terminal with appropriate username.
```
ssh -s username@core -p 830 netconf
```
You should see a long hello message printed out for the netconf capabilities this switch supports. At the end of the message, you should see _urn:ietf:params:netconf:capability:notification:1.1_ listed there like below. You can press "ctrl+c" to end the ssh session.

![json](./images/netconf_capability.png?raw=true "Import JSON")

#### gNMI
The gNMI configuration on the switch is pretty straightforward. Since it's using the dial-in method to pull the telemetry from the switch, most of the configuration lives on the collector, which is Telegraf in our lab. If you ssh through putty to the "core" switch from your windows jumphost. You will see the "core" switch has two commands configured for gNMI insecure mode. 
```
gnxi
gnxi server
```
Note that this implementation is not using a certificate in secure mode. The secure mode is enabled by the commands below which are not covered in this lab.  
```
gnxi
gnxi secure-init
gnxi secure-server
gnxi secure-port 9339
```
You can refer to this [link](https://github.com/jeremycohoe/cisco-ios-xe-programmability-lab-module-5-gnmi) for detailed steps on how to get gNMI secure mode set up.

To check the gNMI status on the switch, execute this command:  
```
show gnxi state detail
```
You should see result like below for non-secure mode in core switch:  
```
core#show gnxi state detail 
Settings
========
  Server: Enabled
  Server port: 50052
  Secure server: Disabled
  Secure server port: 9339
  Secure client authentication: Disabled
  Secure trustpoint: 
  Secure client trustpoint: 
  Secure password authentication: Disabled

GNMI
====
  Admin state: Enabled
  Oper status: Up
  State: Provisioned

  gRPC Server
  -----------
    Admin state: Enabled
    Oper status: Up

  Configuration service
  ---------------------
    Admin state: Enabled
    Oper status: Up

  Telemetry service
  -----------------
    Admin state: Enabled
    Oper status: Up
          
GNOI
====

  Cert Management service
  -----------------
    Admin state: Enabled
    Oper status: Up

  OS Image service
  ----------------
    Admin state: Disabled
    Oper status: Up
    Supported: Not supported on this platform

  Factory Reset service
  ---------------------
    Admin state: Enabled
    Oper status: Up
    Supported: Not supported on this platform

gRPC Tunnel
===========
  Admin state: Enabled
  Oper status: Up
```
#### gRPC
Next, we will spend time focusing on the gRPC configuration on the "access" switch. If you recall, the last Ansible playbook for telemetry you executed has configured the "access" switch for gRPC. You can either ssh to the access switch through the Windows jumphost to check the configuration or use VSCode to view the [telemetry config jinja2 template](templates/telemetry_config.j2).

Below is the gRPC telemetry subscription for CPU 
```
! CPU
telemetry ietf subscription 3301
 encoding encode-kvgpb
 filter xpath /process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds
 source-vrf Mgmt-vrf
 source-address 10.0.0.15
 stream yang-push
 update-policy periodic 500
 receiver ip address {{ telemetry_destination_ip }} 57500 protocol grpc-tcp
```

**_ietf_** specifies this telemetry subscription is based on IETF standard. **_subscription number_** is static number you can assign.

**_encoding_** specifies the the gRPC encoding. In this case, we use key-value Google Protocol Buffers (kvgpb) as this is the encoding method which is supported by Telegraf.

**_filter xpath_** specifies XML Xpath where the data is stored in the database. You can leverage YANG suite to figure out the exact path.

**_stream_** specifies stream type of the telemetry. Stream is the data in the configuration and operational database that is described by a supported YANG model. The _yang-push_ type of stream supports an XPath filter to specify what data is of interest within the stream, and where the XPath expression is based on the YANG model that defines the data of interest. The _yang_notif-native_ type of stream is any YANG notification in the publisher where the underlying source of events for the notification uses Cisco IOS XE native technology. This stream also supports an XPath filter that specifies which notifications are of interest. Update notifications for this stream are sent only when events that the notifications are for occur. Currently, this stream is not supported over Google remote procedure call (gRPC). In this lab, we use _yang-push_.

**_update-policy periodic_** specifies how often the telemetry is sent out to collector. The unit is 1/100 seconds. 500 indicates 5 seconds.

**_receiver ip address_** specifies the collector ip address which is the Telegraf ip address in our lab. _57500_ is the port Telegraf is listening on. _protocol_ is grpc-tcp which is insecure mode. We do support Secure gRPC protocol using TLS. Please refer to this [link](https://github.com/jeremycohoe/cisco-ios-xe-mdt/blob/master/c9300-grpc-tls-lab.md) for details.

The puzzle in the configuration is how to figure out the right xpath for the telemetry data you want to stream from the switch. We suggest you leverage [yangsuite](https://github.com/CiscoDevNet/YANG Suite) to help you on that. 

### Action 1: Examine the access switch telemetry configuration with YANG Suite

In our lab, Yang Suite is pre-configured. You can access it from windows jumphost chrome browser bookmark like below:
![json](./images/YANG Suite-home.png?raw=true "Import JSON")

YANG model files are preloaded in the Yang Suite already. We have created two device profiles for you. One for access switch and the other for core switch. You will need to validate the connections like screenshots below after you have deployed all the ansible playbooks.

Step 1: From menu on the left, select "Setup" -> "Device Profiles"

Step 2: Select "core".

Step 3: Click "Edit selected device".

Step 4: Click "Check connectivity".

You should see all green checkmarks like below.

![json](./images/yang-device-1.png?raw=true "Import JSON")

Repeat these steps for access switch.

To figure out xpath, you can refer to the screenshot below. Pick YANG module you are interested. In this example, we pick cpu related module. You can type "cpu" in "Select YANG modules" box and it will give you the options. After you load the YANG module. You can click the data field and see "Xpath" and "Prefix" shown on the right side. Please NOTE "/" position. In our access switch configuration, we have _filter xpath /process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds_. In YANG Suite, we don't have "/" in front of "Prefix" and we have "/" in front of "Xpath". When you put the xpath in switch configuration, please follow the format _/prefix:xpath_.

Step 1: From menu on the left, select "Explore" -> "YANG".

Step 2: Select a YANG set as "cat9kv".

Step 3: Select YANG modules as "Cisco-IOS-XE-process-cpu-oper".

Step 4: Click "Load modules" on the right.

Step 5: After the module is loaded, expand the module tree. You will find "five-seconds" under cpu-usage/cpu-utilization. Click on it and you will see "Xpath", "Prefix", and "Module" names on the right side.

![json](./images/yang-explore-1.png?raw=true "Import JSON")

When you have xpath figured out, you will be able to complete gRCP telemetry configuration in the switch. You can examine the telemetry configuration in "access" switch in your pod.

Besides exploring xpath, you can use YANG Suite to test out gNMI or gRPC with devices. Follow the screenshots below, let's start with gNMI and see what data we can retrieve from the core switch. Remember the core switch is configured only with gNMI.

Step 1: Select "Protocols" -> "gNMI".

Step 2: Select "cat9kv" YANG Set.

Step 3: Select YANG modules as "Cisco-IOS-XE-process-cpu-oper".

Step 4: Click "Load modules" on the right.

Step 5: Select "core" in Device list.

Step 6: Select "Origin" as RFC 7951.

Step 7: Expand the YANG model tree and click on "five-seconds" field.

Step 8: Click "Build RPC".

Step 9: Click "Run RPC".

![json](./images/yang-gnmi-1.png?raw=true "Import JSON")


After you click "Run RPC", you will have another window popped up showing you the result. Can you tell the value for cpu five seconds?

The practice above is a simple _gNMI get_ option, you can also use gNMI to set value for switch such as VLAN configuration, interface description, etc. You can follow the screenshot below to set MOTD banner for your access switch. (PLEASE DON'T try to change hostname of access switch. It will create a different table for telemetry since we use the hostname to populate gRPC telemetry into InfluxDB.) We have the delete step below also for your reference. Have fun! 

![json](./images/yang-gnmi-2.png?raw=true "Import JSON")

![json](./images/yang-gnmi-3.png?raw=true "Import JSON")


Next, let's explore gRPC with YANG Suite. To receive the telemetry through gRPC from the switch, YANG Suite needs to be the receiver/collector. That means we need to add YANG Suite ip as receiver in the switch telemetry configuration. Let's use cpu 5 seconds telemetry in this case.

### Action 1.5 Modify Access Switch Configuration to send telemetry to YANG Suite
SSH to your access switch from the Windows jumphost using puTTy or your VSCode Terminal Window and add the commands below. Please change # to your pod number.

```
conf t
telemetry ietf subscription 3311
 encoding encode-kvgpb
 filter xpath /process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds
 source-address 10.0.0.15
 source-vrf Mgmt-vrf
 stream yang-push
 update-policy periodic 500
 receiver ip address 10.1.#.16 57500 protocol grpc-tcp
```
These commands creates a new subscription on cpu metrics and send telemetry to YANG Suite. Let's go to YANG Suite to see the output. Follow the screenshot below to see the gRPC telemetry received from the switch.

Step 1: Select "Protocols" -> "gRPC telemetry".

Step 2: Enter 0.0.0.0 in "Listen at IP address" box.

Step 3: Enter 57500 in "Listen at port" box.

Step 4: Click "Start receiver" button.

You should see a pop up window showing "Server started on 0.0.0.0 port 57500". Click "OK".

![json](./images/yang-grpc-1.png?raw=true "Import JSON")

![json](./images/yang-grpc-2.png?raw=true "Import JSON")


You should see the cpu telemetry sent from access switch updated on the screen. You can click "Manage receivers" and then click "Stop" button to stop the receiver. You will see two pop up windows in a row like below. Just click "OK" to confirm.

![json](./images/yang-grpc-3.png?raw=true "Import JSON")

![json](./images/yang-grpc-4.png?raw=true "Import JSON")

![json](./images/yang-grpc-5.png?raw=true "Import JSON")

![json](./images/yang-grpc-6.png?raw=true "Import JSON")

There are much more functions in YANG Suite such as SNMP to Xpath mapping, Ansible and python code generation for Netconf call. Please refer to **_Help_** section inside YANG Suite portal for more guidance about how-to.
![json](./images/help.png?raw=true "Import JSON")


### Telegraf Configuration
Telegraf is developed by Influxdata, the same company that created InfluxDB. Telegraf is a server-based agent for collecting and sending all metrics and events from databases, systems, and IoT sensors. Normally the Telegraf configuration has 4 sections: global agent settings, input settings, output settings, and processors. Output settings determine where the data is written to. In our lab, output goes to InfluxDB database. Input settings include all types of telemetry Telegraf collects. In our lab, we have telemetry collected from the core switch through gNMI as one type of input. Telemetry collected from the access switch through gRPC is another type of input. We also have telemetry collected from the access switch through SNMP as third type of input. You can see Telegraf is flexible enough to collect the mix of different telemetry types. Processors are the functions that transform the data before Telegraf writes them to database. It's very helpful when you have a mix of types of telemetry like our lab.

### Action 2: Examine the Telegraf Configuration
Let's look at the Telegraf configuration in our lab.
#### Output Setting
```
# Output Plugin InfluxDB
[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  bucket = "xxx"
  token = "xxx"
  organization = "xxx"

# Send output to file for debugging
[[outputs.file]]
  files = ["stdout"]
  data_format = "influx"
```
The syntax is pretty straightforward. We have two output destinations in the lab. One is to Influxdb database which listens on tcp port 8086. It's configured under _[[outputs.influxdb_v2]]_. This is the name of output plugin Telegraf supports. It has a specific "bucket", "token" and "organization" defined to access the Influxdb database. The second output directs Telegraf to print the telemetry data received to the terminal. This is helpful when you are working on diagnosing and verifying the telemetry data. When you look the data printed out in the terminal, it follows the format like this:
measurement,tag1=value1,tag2=value2,...,tagn=valuen field1=value1,field2=value2,...fieldn=valuen
Here is example for the cpu 5 seconds output:
```
cpu,device=core,host=telegraf five_seconds=1i 1666837816572038000
```
_cpu_ is the measurement name. _device_ is a tag and its value is _core_. _host_ is another tag and its value is _telegraf_. Notice there is a "space" after _host_ tag. This indicates the data after the space is all fields which are the real telemetry data Telegraf collects from the switch. _five_seconds_ is a field name and its value is _1i_. "i" means integer. _1666837816572038000_ in the end is a unix format timestamp. All data records received by Telegraf and written in the influx format have timestamps associated.  

#### Input Setting for gRPC
```
[[inputs.cisco_telemetry_mdt]]
 ## Telemetry transport can be "tcp" or "grpc".  TLS is only supported when
 ## using the grpc transport.
 transport = "grpc"

 ## Address and port to host telemetry listener
 service_address = ":57500"

 ## Grpc Maximum Message Size, default is 4MB, increase the size.
 max_msg_size = 4000000
```
gRPC configuration uses the _inputs.cisco_telemetry_mdt_ plugin. The parameters are pretty simple. _grpc_ is the protocol we use and Telegraf listens on port _57500_. You can specify a different port if you like. Just make sure the switch has the same port configured for telemetry. _max_msg_size_ has the default value which is sufficient. You can see the gRPC configuration in Telegraf is pretty simple. The switch has the configuration to specify the xpath for the data and is responsible for sending the data to Telegraf. Telegraf is the receiver only in this case. Next, let's look at gNMI input settings.

#### Input Settings for gNMI

```
# Define where the IOS XE gNMI server is and how to auth
[[inputs.gnmi]]
  addresses = ["core:50052"]
  username = "xxx"
  password = "xxx"
  redial = "10s"
  ## gNMI encoding requested (one of: "proto", "json", "json_ietf", "bytes")
  encoding = "json_ietf"

# cpu
[[inputs.gnmi.subscription]]
  name = "cpu"
  origin = "rfc7951"
  path = "/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds"
  subscription_mode = "sample"
  sample_interval = "5s"

# memory
[[inputs.gnmi.subscription]]
 name = "memory"
 origin = "openconfig"
 path = "/system/memory/state"
 subscription_mode = "sample"
 sample_interval = "5s"

# ios version
[[inputs.gnmi.subscription]]
  name = "version"
  origin = "rfc7951"
  path = "/Cisco-IOS-XE-native:native/version"
  subscription_mode = "sample"
  sample_interval = "60s"

# uptime
[[inputs.gnmi.subscription]]
  name = "state"
  origin = "openconfig"
  path = "/system/state"
  subscription_mode = "sample"
  sample_interval = "60s"

# PID and system info
[[inputs.gnmi.subscription]]
  name = "system"
  origin = "rfc7951"
  path = "/Cisco-IOS-XE-device-hardware-oper:device-hardware-data/device-hardware"
  subscription_mode = "sample"
  sample_interval = "300s"

# interfaces counters
[[inputs.gnmi.subscription]]
  name = "interfaces-counter"
  origin = "rfc7951"
  path = "/Cisco-IOS-XE-interfaces-oper:interfaces/interface/statistics"
  subscription_mode = "sample"
  sample_interval = "5s"

# interfaces state
[[inputs.gnmi.subscription]]
  name = "interfaces-state"
  origin = "rfc7951"
  path = "/Cisco-IOS-XE-interfaces-oper:interfaces/interface/oper-status"
  subscription_mode = "sample"
  sample_interval = "5s"

# arp
[[inputs.gnmi.subscription]]
  name = "arp"
  origin = "rfc7951"
  path = "/Cisco-IOS-XE-arp-oper:arp-data"
  subscription_mode = "sample"
  sample_interval = "5s"

# routes
[[inputs.gnmi.subscription]]
  name = "routes"
  origin = "rfc7951"
  path = "/ietf-routing:routing-state/routing-instance[name=default]/ribs/rib[name=ipv4-default]/routes/route/destination-prefix"
  subscription_mode = "sample"
  sample_interval = "5s"

```
Do you see some similarities between the gNMI input settings and the switch gRPC telemetry configuration? Yes, we define the xpath in Telegraf instead of the switch for gNMI since it's a dial-in method. Telegraf dials into switch to pull the telemetry. It's a pub-sub model. Telegraf subscribes to switch's xpath. At the top, we define the switch we want to subscribe to. _core_ is the hostname, port _50052_ and CLI credentials. We use _json_ietf_ as encoding format. After the first _inputs.gnmi_ definition, we have all of the subscriptions listed. The first one is 5-seconds CPU utilization. _cpu_ is the measurement name. Please pay attention to the path _"/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds"_. In the previous section on the switch telemetry configuration, we have the xpath as _/process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds_. You also used YANGsuite to explore how you can get this xpath for the switch configuration. This path value for the same data has a different format in the gNMI Telegraf plugin. Instead of the prefix _"/process-cpu-ios-xe-oper"_, we use the YANG module name _"/Cisco-IOS-XE-process-cpu-oper"_. Pay attention to the position of "/". It's in front of the module name like prefix name in gRPC configuration. The path after ":" is the same between gRPC and gNMI configuration. _subscription_mode_ is "sample" and _sample_interval_ is every 5 seconds. It means we grab this data every 5 seconds.

#### Input Setting for SNMP
```
[[inputs.snmp]]
  agents = ["access"]
  version = 2
  community = "xxx"
  interval = "5s"
  timeout = "5s"
  retries = 3

  # PID
  [[inputs.snmp.field]]
    name = "pid"
    oid = ".1.3.6.1.2.1.47.1.1.1.1.13.1"

# IF-MIB::ifTable contains counters on input and output traffic as well as errors and discards.
[[inputs.snmp.table]]
  name = "interface-snmp"
  oid = "IF-MIB::ifTable"

  # Interface tag - used to identify interface in metrics database
  [[inputs.snmp.table.field]]
    name = "name"
    oid = "IF-MIB::ifDescr"
    is_tag = true

  # IF-MIB::ifXTable contains newer High Capacity (HC) counters that do not overflow as fast for a few of the ifTable counters
[[inputs.snmp.table]]
  name = "interface-snmp"
  oid = "IF-MIB::ifXTable"

  # Interface tag - used to identify interface in metrics database
  [[inputs.snmp.table.field]]
    name = "name"
    oid = "IF-MIB::ifDescr"
    is_tag = true
```

#### Processors
We won't dive into the details. But the configuration below helps to rename tags and measurement names. Some data also have the value type converted to help data visualization in the Grafana dashboard. If you want to learn more about these functions, please refer to this [link](https://docs.influxdata.com/telegraf/v1.21/plugins/). Filter with "Processors" type.

```
[[processors.converter]]
  [processors.converter.fields]
    integer = ["physical", "reserved", "tx-kbps", "rx-kbps", "five_seconds"]

[[processors.rename]]
  order = 1
  [[processors.rename.replace]]
    tag = "source"
    dest = "device"
  [[processors.rename.replace]]
    tag = "agent_host"
    dest = "device"
  [[processors.rename.replace]]
    tag = "name"
    dest = "interface"
  [[processors.rename.replace]]
    measurement = "Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization"
    dest = "cpu"
  [[processors.rename.replace]]
    measurement = "openconfig-system:system/memory/state"
    dest = "memory"
  [[processors.rename.replace]]
    measurement = "Cisco-IOS-XE-interfaces-oper:interfaces/interface/statistics"
    dest = "interfaces-counter"
  [[processors.rename.replace]]
    measurement = "Cisco-IOS-XE-interfaces-oper:interfaces/interface"
    dest = "interfaces-state"
  [[processors.rename.replace]]
    measurement = "openconfig-system:system/state"
    dest = "state"
  [[processors.rename.replace]]
    measurement = "Cisco-IOS-XE-native:native"
    dest = "version"
  [[processors.rename.replace]]
    measurement = "Cisco-IOS-XE-device-hardware-oper:device-hardware-data/device-hardware"
    dest = "system"
  [[processors.rename.replace]]
    measurement = "Cisco-IOS-XE-arp-oper:arp-data/arp-vrf"
    dest = "arp"
  [[processors.rename.replace]]
    field = "tx_kbps"
    dest = "tx-kbps"
  [[processors.rename.replace]]
    field = "rx_kbps"
    dest = "rx-kbps"

[[processors.enum]]
  [[processors.enum.mapping]]
    # Change interface status to number
    field = "oper_status"
    dest = "status_code"
    [processors.enum.mapping.value_mappings]
      if-oper-state-ready = 1
      if-oper-state-no-pass = 0
```

Now you have learned how Telegraf is configured. Let's see what data you see at Telegraf. Keep in mind, core switch has all telemetry done through gNMI subscription and access switch has mix of gRPC and snmp. To view the data received at Telegraf, please go to your windows jumphost. Open Visual Code and have terminal opened like screenshot below. There are two bash files staged. _"telegraf-access.sh"_ and _"telegraf-core.sh"_. Let's execute them one by one and observe the output. Enter "yes" when asked about ssh key. When the script asks for password, please enter the one told by your proctor. You should see results like below. 



### InfluxDB Configuration
InfluDB is a popular time series database. It's suitable for storing streaming data collected from IoT devices and network devices. Fortunately we don't need to configure the InfluxDB database in as much detail as Telegraf. The initialization of the lab creates the logins, database, and token for authentication. That's all we need. Please refer to [InfluxDB documentation](https://docs.influxdata.com/influxdb/v2.4/get-started/) to learn more about this time series database. Another popular database for storing streaming data is [Prometheus](https://prometheus.io/), which is very popular for network monitoring.

### Grafana Configuration
[Grafana](https://grafana.com/) is a really popular dashboard tool to visualize telemetry data. It's widely used in many areas. It provides an on premise type of install such as docker and VM. It also provides a cloud deployment option for ease of use.

#### Action 3: Examine Grafana Dashboard
Please go to the Windows jumphost Chrome browser. Click the bookmark for Grafana and login to it. You will see a dashboard for our lab when you log in like below. Since you executed the telemetry Ansible playbook early on, we should see some telemetry data displayed in the dashboard already for the core and access switches. 

![json](./images/grafana-home-1.png?raw=true "Import JSON")

You have the _"Device"_ drop down menu in the top left corner to select which device you want to view in the dashboard. The core switch has telemetry collected through gNMI. The access switch has telemetry collected through mix of gRPC and SNMP. You can see _"Serial Number"_, _"PID"_, _"Version"_, _"Up Time"_, _"ARP"_, _"Routes"_, _"CPU"_, _"Memory"_, _"Interfaces"_, and _"Topology"_ information. All of these sections are called panels inside the Grafana dashboard. These panels have different styles you can customize with. Table view, graph view, gauge view, etc. The _"Topology"_ panel is enabled by a Grafana plugin called "flowcharting". You can check this [link](https://grafana.com/grafana/plugins/agenty-flowcharting-panel/) for more details. In the topology panel, you should see some numbers by tx or rx of interfaces. These numbers indicate the throughput through the interfaces in tx or rx direction. Most links (except the link between wan and server1) have colors. Green means link is up and operational. Red means link is down. Now let's do couple of tests.

First, we will need to generate some traffic. Please go to the Windows jumphost. Open the Chrome browser and click _"client1_vnc"_ or _"client2_vnc"_. You will see the linux desktop show up. Click the _"iperf3"_ icon on the desktop. Assuming you already deployed all the ansible playbooks, this iperf3 script should generate traffic from client1 or client2 to server1 depending on which client you selected. The script generates traffic for 2 mins and stops. The example below is for client1 but it is same for client2 vnc.
![json](./images/client-iperf3.png?raw=true "Import JSON")

Observe the _"Interfaces"_ panel and _"Topology"_ panel to see the changes. You should see symmetric trending lines in _"Interfaces"_ panel no matter which switch you chose in the _Device_ dropdown menu. The _"Topology"_ panel will also display the throughput numbers for specific interfaces.

![json](./images/grafana-traffic.png?raw=true "Import JSON")

Now you have seen the traffic reflected on the dashboard through different panels. Let's do another test. ssh to the access switch through the Windows jumphost. Shut down interface Gi1/0/1 or Gi1/0/2 which are connected to client1 and client2, respectively. Observe the link color change. You should see the link you shut down turn red. Feel free to no shut the links.

![json](./images/grafana-link-shut.png?raw=true "Import JSON")

So far you have seen some power of the dashboard. Wondering what's behind the panel? Let's look at how Grafana queries InfluxDB on the backend.

Let's use our favorite CPU metrics. Click on name "CPU" in the panel like the screenshot below. Click "Edit". 
![json](./images/grafana-cpu-1.png?raw=true "Import JSON")

You will see panel edit page shown up. 

![json](./images/grafana-cpu-2.png?raw=true "Import JSON")

In this page, you will define the magic. We have the data source as "InfluxDB". That's the data source Grafana queries against. Down below, you have the flux query section. This is where you write your database query. The language used in InfluxDB 2.x is called Flux. It used to be SQL query in 1.x version. Influxdb 2.x switches to Flux language which is an even more powerful and flexible query language designed for time series databases. The top statement means query from bucket (database) called "telemetry". The Second statement states the time range to display the data. These are default variables fed by the panel time range selection. The third line is how we define the data. "filter" function (fn) is a way to select the interesting data based on the conditions defined. In this example, the measurement name is "cpu", field name is "five_seconds", and tag name is a variable called "Device" which is determined by the device drop down menu in the top left corner of the panel. These conditions must be met for the specific data we are interested in. You can use the Flux language to write more complex queries. Other panels in this lab have more complex queries. Feel free to tour around. If you'd like to learn more about Flux, please go to their [official tutorial](https://docs.influxdata.com/influxdb/cloud/query-data/get-started/). There are many good examples.

This is all we'd like you to examine inside the Grafana dashboard but feel free to take a look how the panel is setup. Personally I really like the flowcharting plugin. It can make the topology much more dynamic.

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

Congratulations! You have finished the MDT section of the lab. We hope you can see how flexible the TIG stack is to collect telemetry from the switches and visualize them in the dashboard. There are a lot to explore with TIG to customize your dashboards. Please refer to the ppt deck for additional resources on the TIG stack.