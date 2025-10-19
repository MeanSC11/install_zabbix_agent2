#!/bin/bash
# ======================================================
# Zabbix Agent2 Installation Script for Ubuntu 24.04
# Version: 7.4
# Author: MeanSC11 (converted from Ansible playbook)
# ======================================================

# --- Variables ---
ZBX_SERVER_IP="xxx.xxx.xxx.xxx"
ZBX_REPO_PKG="/tmp/zabbix-release_latest_7.4+ubuntu24.04_all.deb"
ZBX_CONF="/etc/zabbix/zabbix_agent2.conf"

# --- Root Check ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or using sudo"
  exit 1
fi

echo "Starting Zabbix Agent2 installation..."

# --- Download Zabbix repo package ---
echo "Downloading Zabbix repository package..."
wget -q https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb -O "$ZBX_REPO_PKG"

# --- Install the repository package ---
echo "Installing repository..."
dpkg -i "$ZBX_REPO_PKG"

# --- Update apt package cache ---
echo "Updating apt package cache..."
apt update -y

# --- Install Zabbix Agent2 and plugin packages ---
echo "Installing Zabbix Agent2 and plugins..."
apt install -y zabbix-agent2 zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

# --- Configure Zabbix Agent2 ---
echo "Configuring Zabbix Agent2..."

# Set the Server parameter
sed -i "s/^Server=.*/Server=${ZBX_SERVER_IP}/" "$ZBX_CONF"
grep -q "^Server=" "$ZBX_CONF" || echo "Server=${ZBX_SERVER_IP}" >> "$ZBX_CONF"

# Set the ServerActive parameter
sed -i "s/^ServerActive=.*/ServerActive=${ZBX_SERVER_IP}/" "$ZBX_CONF"
grep -q "^ServerActive=" "$ZBX_CONF" || echo "ServerActive=${ZBX_SERVER_IP}" >> "$ZBX_CONF"

# Set the Hostname automatically using the system hostname
HOSTNAME=$(hostname)
sed -i "s/^Hostname=.*/Hostname=${HOSTNAME}/" "$ZBX_CONF"
grep -q "^Hostname=" "$ZBX_CONF" || echo "Hostname=${HOSTNAME}" >> "$ZBX_CONF"

# --- Enable and start the Zabbix Agent2 service ---
echo "Enabling and starting zabbix-agent2 service..."
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

# --- Verify the service status ---
echo "Checking zabbix-agent2 service status..."
systemctl status zabbix-agent2 --no-pager

echo "Zabbix Agent2 installation and configuration completed!"
echo "Agent2 is now connected to Zabbix Server: ${ZBX_SERVER_IP}"
