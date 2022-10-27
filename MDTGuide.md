## MDT Lab Guide

### Part 1: Explore MDT config with switch and TIG stack

Now you have switches and router all configured through ansible. Well done! At this moment, telemetry has been collected through telegraf. Telegraf, data collector, outputs the data into influxDB, time series database. Then grafana visualizes the telemetry data in dashboard. In this lab, we have telegraf, influxDB, and grafana all configured already. There is no configuration change needed in this section. We will go through switch configuration, telegraf configuration, and grafana to explain how they are all tied together. Here is high level flow how the telemetry is collected through the TIG stack.

![json](./images/tig.png?raw=true "Import JSON")

There are several roles regarding to Model Driven Telemetry.
* Publisher: Network element that sends the telemetry data. In our lab, this is the switch.
* Receiver: This is also called collector. It receives the telemetry data. In our lab, this is telegraf.
* Controller: Network element that creates subscriptions but does not receive the telemetry data. In our lab, this is the switch.
* Suscriber: Network element that creates subscriptions. In our lab, telegraf is the subscriber for gNMI implmentation to subscribe to the switch telemetry data.

Telegraf plays a critical role in our lab since it collects all the telemetry data through gRPC/gNMI/snmp and normalize them before it writes to influxDB database. InfluxDB in our lab doesn't have much customized configuration after the initilization of database. Grafana has different types of queries to influxDB to fetch the telemetry for dashboard virtualization. 

There are three ways we use to collect the telemetry from the switches. 
* gRPC: We use gRPC dial-out method on "access" switch. You have executed ansible playbook in the last section of the lab to configure the access switch to send telemetry to telegraf. 
* gNMI: We use gNMI dial-in method on "core" switch. Most of gNMI configuration specifying the yang xpath is done through telegraf. If you compare gNMI configuration to gRPC configuration, we move all the xpath specification from switch side to telegraf side.
* snmp: We also uses snmp in this lab to pull product ID (PID) and interface operational status on "access" switch. This will show you how flexible TIG stack is to support mix types of telemetry.

In the next sections, we will go through the switch, telegraf, influxDB, and grafana configurations individually.

### Switch Configuration On Telemetry
Model Driven Telemetry configuration in switch needs several key prerequisites.
* YANG. Since all data is stored in database, we will need to enable the access to database in switch from the collector (telegraf). **netconf-yang** command needs to be configured on the device for telemetry to work.
* XML Xpath. XPath is XML Path Language. This specifies where the telemetry data is. 
* _urn:ietf:params:netconf:capability:notification:1.1_ capability must be listed in hello messages. This capability is advertised only on devices that support IETF telemetry.

There are two useful commands to validate the prerequisites:
```
show platform software yang-management process
```
You can ssh to "core" or "access" switch and run this command above. The output should be like below. All processes are in "running" state.

![json](./images/core_show_process.png?raw=true "Import JSON")

Another command is to validate the capability prerequsite mentioned above. Execute this command in your Visual Code terminal with appropriate username.
```
ssh -s username@core -p 830 netconf
```
You should see a long hello message printed out for the netconf capabilities this switch supports. In the end of the message, you should see _urn:ietf:params:netconf:capability:notification:1.1_ listed there like below. You can press "ctrl+c" to end ssh session.

![json](./images/netconf_capability.png?raw=true "Import JSON")

#### gNMI
gNMI configuration in switch is pretty straightforward. Since it's dial-in method to pull the telemetry from the switch, its most configuration lives in the collector which is telegraf in our lab. If you ssh through putty to the "core" switch from your windows jumphost. You will see the "core" switch has two commands configured for gNMI insecure mode. 
```
gnxi
gnxi server
```
Note that this implementation is not using certificate in secure mode. The secure mode is enabled by commands as below which is not covered in this lab.
```
gnxi
gnxi secure-init
gnxi secure-server
gnxi secure-port 9339
```
You can refer to this [link](https://github.com/jeremycohoe/cisco-ios-xe-programmability-lab-module-5-gnmi) for detailed steps on how to get gNMI secure mode set up.

#### gRPC
Next, we will spend time to focus on gRPC configuration in the "access" switch. If you recall, the last ansible playbook for telemetry you executed has configured "access" switch for gRPC. You can either ssh to access switch through windows jumphost to check the configuration. You can also use Visual Code to view the [telemetry config jinja2 template](templates/telemetry_config.j2).

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

**_ietf_** specifies this telemetry is based on IETF standard. **_subscription number_** is static number you can assign.

**_encoding_** specifies the the gRPC encoding. In this case, we use key-value Google Protocol Buffers (kvgpb) as encoding method which is supported by telegraf.

**_filter xpath_** specifies XML Xpath where the data is stored in database. You can leverage yang suite to figure out the exact path.

**_stream_** specifies stream type of the telemetry. Stream is the data in configuration and operational database that is described by a supported YANG model. _yang-push_ type of stream supports an XPath filter to specify what data is of interest within the stream, and where the XPath expression is based on the YANG model that defines the data of interest. _yang_notif-native_ type of stream is any YANG notification in the publisher where the underlying source of events for the notification uses Cisco IOS XE native technology. This stream also supports an XPath filter that specifies which notifications are of interest. Update notifications for this stream are sent only when events that the notifications are for occur. Currently, this stream is not supported over Google remote procedure call (gRPC). In this lab, we use _yang-push_.

**_update-policy periodic_** specifies how often the telemetry is sent out to collector. unit is 1/100 seconds. 500 indicates 5 seconds.

**_receiver ip address_** specifies the collector ip address which is telegraf ip address in our lab. _57500_ is the port telegraf is listening on. _protocol_ is grpc-tcp which is insecure mode. We do support tls based on grpc protocol. Please refer to this [link](https://github.com/jeremycohoe/cisco-ios-xe-mdt/blob/master/c9300-grpc-tls-lab.md) for details.

The puzzle in the configuration is how to figure out the right xpath for the telemetry data you want to stream from the switch. We suggest you leverage [yangsuite](https://github.com/CiscoDevNet/yangsuite) to help you on that. 

### Action 1: Examine the access switch telemetry configuration with yangsuite

In our lab, yangsuite is pre-configured. You can access it from windows jumphost chrome browser.
![json](./images/yangsuite-home.png?raw=true "Import JSON")

YANG model files are preloaded in the yangsuite already. You will need to enter ip addresses for access and core switches like screenshots below. Go to "Setup"->"Device profiles" and then select "access" to edit the device profile. access switch ip is 10.1.#.15. core switch is 10.1.#.14. # is your assigned pod number.
![json](./images/yang-device-1.png?raw=true "Import JSON")
![json](./images/yang-device-2.png?raw=true "Import JSON")

Repeat these steps for core switch.

To figure out xpath, you can refer to the screenshot below. Pick YANG module you are interested. In this example, we pick cpu related module. You can type "cpu" in "Select YANG modules" box and it will give you the options. After you load the YANG module. You can click the data field and see "Xpath" and "Prefix" shown on the right side. Please NOTE "/" position. In our access switch configuration, we have _filter xpath /process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds_. In yangsuite, you can see we don't have "/" in front of prefix and we have "/" in front of Xpath. When you put the xpath in switch configuration, please follow the format _/prefix:xpath_.
![json](./images/yang-explore-1.png?raw=true "Import JSON")

When you have xpath figured out, you will be able to complete gRCP telemetry configuration in the switch. You can examine the telemetry configuraiton in "access" switch of your pod.

Besides exploring xpath, you can use yangsuite to test out gNMI or gRPC with devices. Follow the screenshots below, let's start with gNMI and see what data we can retrieve from the core switch. Remember the core switch is configured only with gNMI.
![json](./images/yang-gnmi-1.png?raw=true "Import JSON")

After you click "Run RPC", you will have another window popped up showing you the result. Can you tell the value for cpu five seconds?

The practice above is a simple _gNMI get_ option, you can also use gNMI to set value for switch such as VLAN configuration, interface description, etc. Feel free to explore that function in your lab.

Next, let's explore gRPC with yangsuite. To receive the telemtry through gRPC from the switch, yangsuite needs to be the receiver/collector. That means we need to add yangsuite ip as receiver in the switch telemetry configuration. Let's use cpu 5 seconds telemetry in this case. ssh to your access switch in windows jumphost and add two commands below. Please change # to your pod number.
```
telemetry ietf subscription 3301
receiver ip address 10.1.#.16 57500 protocol grpc-tcp
```
These two commands will make the switch send cpu telemetry to yangsuite. Let's go there to see the output. Follow the screenshot below to see the gRPC telemetry received from the switch.

![json](./images/yang-grpc-1.png?raw=true "Import JSON")

![json](./images/yang-grpc-2.png?raw=true "Import JSON")

You should see the cpu telemetry sent from access switch updated on the screen. You can click "Stop telemetry receiver" to stop receiving the telemetry.

Feel free to explore gNMI and gRPC with other xpath you like to explore.

### Telegraf Configuration
Telegraf is developed by influxdata, same company who created influxDB. Telegraf is a server-based agent for collecting and sending all metrics and events from databases, systems, and IoT sensors. Normally telegraf configuration has 4 sections: global agent setting, input setting, output setting, and processors. Output setting determines where the data is written to. In our lab, output goes to influxDB database. Input setting includes all types of telemetry telegraf collects. In our lab, we have telemetry collected from core switch through gNMI as one type of input. Telemetry collected from access switch through gRPC is another type of input. We also have telemetry collected from access switch through snmp as 3rd type of input. You can see telegraf is flexible to collect the mix of different telemetries. Processors are the functions to transform the data before telegraf writes them to database. It's very helpful when you have mix type of telemetry like our lab.

### Action 2: Examine telegraf configuration
Let's look at the telegraf configuration in our lab.
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
The syntax is pretty straightforward. We have two output destinations in the lab. One is to influxdb database which listens on tcp port 8086. It's configured under _[[outputs.influxdb_v2]]_. This is the name of output plugin telegraf supports. It has specific "bucket", "token" and "organization" defined to access influxdb database. The second output is print out the data received at telegraf to the terminal. This is helpful when you diagnose and verify the telemetry data. When you look the data printed out in the terminal, it follows the format like this:
measurement,tag1=value1,tag2=value2,...,tagn=vlauen field1=value1,field2=value2,...fieldn=valuen
Here is example for the cpu 5 seconds output:
```
cpu,device=core,host=telegraf five_seconds=1i 1666837816572038000
```
_cpu_ is the measurement name. _device_ is a tag and its value is _core_. _host_ is another tag and its value is _telegraf_. Notice there is a "space" after _host_ tag. This indicates the data after the space is all fields which are the real telemetry data telegraf collects from the switch. _five_seconds_ is a field name and its value is _1i_. "i" means integer. _1666837816572038000_ in the end is a unix format timestamp. All data records recevied at telegraf and written in influx format have timestamps associated. 

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
gRPC configuration uses _inputs.cisco_telemetry_mdt_ plugin. The prameters are pretty simple. _grpc_ is the protocol we use and telegraf listens on port _57500_. You can specify different port if you like. Just to make sure switch has the same port configured for telemetry. _max_msg_size_ has default value which is sufficient. You can see gRPC configuration in telegraf is pretty simple. The switch has the configuration to specify the xpath for the data and is responsible for sending the data to telegraf. Telegraf is the receiver only in this case. Next, let's look at gNMI input setting.

#### Input Setting for gNMI

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
Do you see some similarities between gNMI input setting and switch gRPC telemetry configuration? Yes, we define xpath in telegraf instead of switch for gNMI since it's a dial-in method. telegraf dials into switch to pull the telemetry. It's a pub-sub model. Telegraf subscribes to switch's xpath. At the top, we define the switch we want to subscribe to. _core_ is the hostname, port _50052_ and CLI credentials. We use _json_ietf_ as encoding format. After first _inputs.gnmi_ definition, we have all the subscriptions listed. The first one is 5-seconds cpu utilization. _cpu_ is the measurement name. Please pay attention to the path _"/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds"_. In previous section of switch telemetry configuration, we have xpath as _/process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds_. You also used yangsuite to explore how you can get this xapth for switch configuration. This path value for the same data has different format in gnmi telegraf plugin. Instead of prefix _"/process-cpu-ios-xe-oper"_, we use YANG module name _"/Cisco-IOS-XE-process-cpu-oper"_. Pay attention to the position of "/". It's in front of module name like prefix name in grpc configuration. The path after ":" is same between grpc and gnmi configuration. _subscription_mode_ is "sample" and _sample_interval_ is every 5 seconds. It means we grab this data every 5 seconds.

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
We won't dive into the details. But the configuration below help rename tags and measurement names. Some data also have the value type converted to help data visulization in Grafana dashbaord. If you want to learn more about these functions. Please refer to this [link](https://docs.influxdata.com/telegraf/v1.21/plugins/). Filter with "Processors" type.

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

### InfluxDB Configuration
InfluDB is a popular time series database. It's suitable for storing streaming data collected from IoT devices and network devices. Fortunately we don't need to configure InfluxDB database in much details like telegraf. The initilization of the lab creates the logins, database, and token for authentication. That's all we need. Please refer to [influxDB doc](https://docs.influxdata.com/influxdb/v2.4/get-started/) to learn more about this time series database. Another popular database for storing streaming data is [Prometheus](https://prometheus.io/), very popular for network monoitoring.

### Grafana Configuration
[Grafana](https://grafana.com/) is really popular dashboard tool to visualize telemetry data. It's widely used in many areas. It provides on premise type of install in docker and VM. Also it provides cloud option for ease of use. 

\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

Congratulations! You have finished the MDT section of the lab. Hope you can see how flexible the TIG stack is to collect telemetry from the switches and visualize them in the dashboard. There are a lot to explore with TIG to customize your dashboards. Please refer to the ppt deck for additional resources on TIG stack.