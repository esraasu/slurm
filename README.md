# 🖥️ Slurm Cluster Lab  
Vagrant + Libvirt + Ansible (Ubuntu 22.04)

This project provisions a 3-node Slurm cluster locally using Infrastructure as Code.

---

# 📦 Installation Guide

## 1️⃣ Install Requirements (Fedora Host)

```bash
sudo dnf install -y \
  vagrant \
  vagrant-libvirt \
  libvirt \
  qemu-kvm \
  ansible \
  git
```

Enable libvirt:

```bash
sudo systemctl enable --now libvirtd
```

Verify:

```bash
virsh list --all
```

---

## 2️⃣ Clone the Repository

```bash
git clone git@github.com:esraasu/slurm.git
cd slurm
```

---

## 3️⃣ Create Libvirt Network

Before running Vagrant, create the provisioning network:

```bash
virsh net-define slurm-net.xml
virsh net-start slurm-net
virsh net-autostart slurm-net
```

Verify:

```bash
virsh net-list --all
```

You should see:

```
slurm-net   active
```

---

## 4️⃣ Deploy the Cluster

```bash
vagrant up --provider=libvirt
```

This will:

- Create 3 Ubuntu 22.04 VMs
- Assign static IPs
- Configure Slurm using Ansible
- Setup Munge authentication
- Configure Chrony time sync

---

## 🧠 Cluster Topology

| Node | Role        | IP              |
|------|------------|----------------|
| head | Controller | 192.168.56.10  |
| c1   | Compute    | 192.168.56.11  |
| c2   | Compute    | 192.168.56.12  |

---

## 5️⃣ Verify Installation

SSH into head node:

```bash
vagrant ssh head
```

Check cluster status:

```bash
sinfo
```

Expected output:

```
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
debug*       up   infinite      2   idle c1,c2
```

Run test job:

```bash
srun hostname
```

---

## 🧹 Destroy Environment

```bash
vagrant destroy -f
```

---

# 🏗️ Project Structure

```
.
├── Vagrantfile
├── slurm-net.xml
├── ansible/
│   ├── site2.yml
│   └── roles/
│       └── slurm_cluster/
│           ├── tasks/
│           └── handlers/
└── .gitignore
```

---

# ⚙️ Technologies Used

- Vagrant
- Libvirt (KVM)
- Ansible
- Slurm
- Munge
- Chrony
- Ubuntu 22.04
