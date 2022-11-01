#!/bin/sh
ssh dcloud@ubuntu 'docker logs -n 100 clab-testdrive-telegraf | grep core'
