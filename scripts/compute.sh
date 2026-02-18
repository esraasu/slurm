#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[compute] installing slurmd"
apt-get install -y slurmd

# 1) Chrony client (sync from head)
echo "[compute] configuring chrony client -> head"
# comment out default pools
sed -i 's/^\(pool \)/#\1/g' /etc/chrony/chrony.conf || true
sed -i 's/^\(server \)/#\1/g' /etc/chrony/chrony.conf || true

grep -q '^server head iburst' /etc/chrony/chrony.conf || cat >>/etc/chrony/chrony.conf <<'EOF'

# Sync only from head
server head iburst
EOF

systemctl restart chrony

# 2) Munge key from shared folder (wait up to 60s)
echo "[compute] waiting for /vagrant_shared/munge.key"
for i in $(seq 1 60); do
  [[ -f /vagrant_shared/munge.key ]] && break
  sleep 1
done
if [[ ! -f /vagrant_shared/munge.key ]]; then
  echo "[compute] ERROR: munge.key not found in shared folder"
  exit 1
fi

cp -f /vagrant_shared/munge.key /etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
systemctl enable --now munge

# quick munge self-test
munge -n | unmunge >/dev/null

# 3) Slurm config from shared folder
echo "[compute] waiting for /vagrant_shared/slurm.conf"
for i in $(seq 1 60); do
  [[ -f /vagrant_shared/slurm.conf ]] && break
  sleep 1
done
if [[ ! -f /vagrant_shared/slurm.conf ]]; then
  echo "[compute] ERROR: slurm.conf not found in shared folder"
  exit 1
fi

cp -f /vagrant_shared/slurm.conf /etc/slurm/slurm.conf

# ensure spool dir exists
mkdir -p /var/lib/slurm/slurmd
chown -R slurm:slurm /var/lib/slurm

# 4) Start slurmd
systemctl enable --now slurmd

echo "[compute] done"

