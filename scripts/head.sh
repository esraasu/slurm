#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[head] installing slurmctld + slurmd (optional)"
apt-get install -y slurmctld slurmd

# 1) Chrony as server
echo "[head] configuring chrony server"
grep -q '^allow 192\.168\.56\.0/24' /etc/chrony/chrony.conf || cat >>/etc/chrony/chrony.conf <<'EOF'

# Allow cluster to sync from head
allow 192.168.56.0/24
local stratum 10
EOF

systemctl restart chrony

# 2) Munge key (generate once) and share via synced folder
echo "[head] generating munge key (if missing)"
if [[ ! -f /etc/munge/munge.key ]]; then
  mungekey --create
fi
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key

systemctl enable --now munge

# Copy key to shared folder so computes can pull it
cp -f /etc/munge/munge.key /vagrant_shared/munge.key
chmod 400 /vagrant_shared/munge.key || true

# 3) Create slurm.conf and share it
echo "[head] writing slurm.conf"
cat >/etc/slurm/slurm.conf <<'EOF'
ClusterName=slurm-lab
ControlMachine=head
SlurmUser=slurm
SlurmdUser=root

StateSaveLocation=/var/lib/slurm/slurmctld
SlurmdSpoolDir=/var/lib/slurm/slurmd

SwitchType=switch/none
MpiDefault=none
SlurmctldPort=6817
SlurmdPort=6818

# Avoid cgroup/freezer issues on Ubuntu 22 lab
ProctrackType=proctrack/linuxproc

ReturnToService=2
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core

SlurmctldLogFile=/var/log/slurmctld.log
SlurmdLogFile=/var/log/slurmd.log

# Nodes (VMs with ~2GB RAM => set RealMemory lower than reported)
NodeName=c1 CPUs=2 Sockets=2 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=1900 State=UNKNOWN
NodeName=c2 CPUs=2 Sockets=2 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=1900 State=UNKNOWN

PartitionName=debug Nodes=c1,c2 Default=YES MaxTime=INFINITE State=UP
EOF

cp -f /etc/slurm/slurm.conf /vagrant_shared/slurm.conf

# 4) Slurm state dir
mkdir -p /var/lib/slurm/slurmctld /var/lib/slurm/slurmd
chown -R slurm:slurm /var/lib/slurm

# 5) Start slurmctld (controller)
systemctl enable --now slurmctld

echo "[head] done"
echo "[head] tip: wait 10-20s then check: sinfo"

