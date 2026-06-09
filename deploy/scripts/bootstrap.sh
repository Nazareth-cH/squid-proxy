#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Запусти с sudo"
    exit 1
fi

apt update
apt install -y ufw curl

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 3128/tcp
ufw --force enable

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Создаём .env из .env.example, если его нет
if [ ! -f ../.env ]; then
    cp ../.env.example ../.env
    echo "Файл .env создан из .env.example"
fi

echo "Bootstrap завершён."
