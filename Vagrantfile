# -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :"kernel-update" => {
    :box_name => "generic/centos9s",
    :cpus => 16,
    :memory => 8192,
  }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.synced_folder ".", "/vagrant"
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxname.to_s
      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
      box.vm.provision "shell", path: "provision.sh", privileged: false
    end
  end
end
