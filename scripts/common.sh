#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-unknown}"

export DEBIAN_FRONTEND=noninteractive

echo "[common] role=${ROLE}"

# Basic packages
apt-get update -y
apt-get install -y chrony munge slurm-client

# Hostnames + hosts file (ثابت للـ lab)
cat >/etc/hosts <<'EOF'
127.0.0.1 localhost
192.168.56.10 head
192.168.56.11 c1
192.168.56.12 c2
EOF

# Chrony baseline (هنكمّل role-specific في head/compute)
systemctl enable --now chrony

# Ensure munge dirs exist
mkdir -p /etc/munge /var/lib/munge /var/log/munge
chown -R munge:munge /etc/munge /var/lib/munge /var/log/munge
chmod 0755 /etc/munge /var/lib/munge /var/log/munge

# Ensure slurm dirs exist
mkdir -p /etc/slurm
mkdir -p /var/lib/slurm/slurmd
chown -R slurm:slurm /var/lib/slurm

echo "[common] done"

