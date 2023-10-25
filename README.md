# Zabbix Template S.M.A.R.T. SSD Samsung

## Installation
1. install smartmontools, jq, sudo
```bash
apt update && apt install smartmontools jq sudo -y
```
2. import smart_ssd_samsung.yaml to your zabbix system
3. copy template user parameters file and sudo privileges
```bash
git clone https://github.com/vargaloid/zabbix_template_samsung.ssd.smart.git
cd zabbix_template_smart_ssd_samsung
cp zabbix /etc/sudoers.d/
cp ssd_smart_samsung.conf /etc/zabbix/zabbix_agent2.d/ || cp ssd_smart_samsung.conf /etc/zabbix/zabbix_agent.d/ 
systemctl restart zabbix-agent2 || systemctl restart zabbix-agent
```
