#!/bin/bash
# ======================================================
# Zabbix Agent2 Installation Script for Ubuntu 24.04
# Version: 7.4
# ======================================================

ZBX_REPO_PKG="/tmp/zabbix-release_latest_7.4+ubuntu24.04_all.deb"
ZBX_CONF="/etc/zabbix/zabbix_agent2.conf"

# --- Root Check ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or using sudo"
  exit 1
fi

# --- Ask for Zabbix Server IP ---
read -rp "Enter Zabbix Server IP: " ZBX_SERVER_IP

if [[ -z "$ZBX_SERVER_IP" ]]; then
  echo "Zabbix Server IP cannot be empty"
  exit 1
fi

echo "Starting Zabbix Agent2 installation..."

# --- Download Zabbix repo package ---
echo "Downloading Zabbix repository package..."
wget -q https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb -O "$ZBX_REPO_PKG"

# --- Install repository ---
echo "Installing repository..."
dpkg -i "$ZBX_REPO_PKG"

# --- Update apt ---
echo "Updating apt package cache..."
apt update -y

# --- Install Agent2 ---
echo "Installing Zabbix Agent2 and plugins..."
apt install -y zabbix-agent2 \
               zabbix-agent2-plugin-mongodb \
               zabbix-agent2-plugin-mssql \
               zabbix-agent2-plugin-postgresql

echo "Configuring Zabbix Agent2..."

# --- Configure Server ---
sed -i "s/^Server=.*/Server=${ZBX_SERVER_IP}/" "$ZBX_CONF"
grep -q "^Server=" "$ZBX_CONF" || echo "Server=${ZBX_SERVER_IP}" >> "$ZBX_CONF"

# --- Configure ServerActive ---
sed -i "s/^ServerActive=.*/ServerActive=${ZBX_SERVER_IP}/" "$ZBX_CONF"
grep -q "^ServerActive=" "$ZBX_CONF" || echo "ServerActive=${ZBX_SERVER_IP}" >> "$ZBX_CONF"

# ======================================================
# Hostname Configuration (ตาม requirement ใหม่)
# - Comment Hostname=
# - Enable HostnameItem=system.hostname
# ======================================================

# Comment Hostname= line (ถ้ามี)
sed -i 's/^Hostname=/# Hostname=/' "$ZBX_CONF"

# Uncomment HostnameItem และตั้งค่าเป็น system.hostname
if grep -q "^# HostnameItem=" "$ZBX_CONF"; then
    sed -i 's/^# HostnameItem=.*/HostnameItem=system.hostname/' "$ZBX_CONF"
elif grep -q "^HostnameItem=" "$ZBX_CONF"; then
    sed -i 's/^HostnameItem=.*/HostnameItem=system.hostname/' "$ZBX_CONF"
else
    echo "HostnameItem=system.hostname" >> "$ZBX_CONF"
fi

# --- Restart Service ---
echo "Enabling and restarting zabbix-agent2..."
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

echo "Checking zabbix-agent2 service status..."
systemctl status zabbix-agent2 --no-pager

echo "=============================================="
echo "Zabbix Agent2 installation completed!"
echo "Connected to Zabbix Server: ${ZBX_SERVER_IP}"
echo "Hostname will be auto-detected via system.hostname"
echo "=============================================="
