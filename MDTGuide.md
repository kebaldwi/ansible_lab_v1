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

**_stream_** specifies 



### Telegraf Configuration


### InfluxDB Configuration


### Grafana Configuration


\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

Congratulations! You have finished the MDT section of the lab. Hope you can see how flexible the TIG stack is to collect telemetry from the switches and visualize them in the dashboard. There are a lot to explore with TIG to customize your dashboards. Please refer to the ppt deck for additional resources on TIG stack.