#!/bin/bash
# 临时生效（重启失效）
sudo sh -c 'echo 0 > /proc/sys/kernel/perf_event_paranoid'
# 永久生效
sudo nano /etc/sysctl.conf
# 添加一行
kernel.perf_event_paranoid = 0
# 重载
sudo sysctl -p