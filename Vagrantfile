Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.ssh.insert_key = false

  nodes = [
    { name: "head", ip: "192.168.56.10", mem: 2048, cpu: 2 },
    { name: "c1",   ip: "192.168.56.11", mem: 2048, cpu: 2 },
    { name: "c2",   ip: "192.168.56.12", mem: 2048, cpu: 2 },
  ]

  nodes.each do |n|
    config.vm.define n[:name] do |node|
      node.vm.hostname = n[:name]

      node.vm.network "private_network",
        ip: n[:ip],
        libvirt__network_name: "slurm-net",
        libvirt__dhcp_enabled: false

      node.vm.provider :libvirt do |lv|
        lv.cpus = n[:cpu]
        lv.memory = n[:mem]
        lv.machine_type = "q35"
        lv.nic_model_type = "virtio"
        lv.disk_bus = "virtio"
      end

      # ✅ Run Ansible ONCE (after head is up), and it configures all nodes via inventory
      if n[:name] == "head"
        node.vm.provision "ansible" do |ansible|
          ansible.playbook = "ansible/site2.yml"
          ansible.inventory_path = "ansible/inventory"
          ansible.compatibility_mode = "2.0"
          ansible.limit = "all"
          ansible.raw_arguments = ["--limit=all"]
        end
      end
    end
  end
end

