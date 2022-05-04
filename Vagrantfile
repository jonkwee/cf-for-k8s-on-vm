# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.provider "vmware_desktop" do |v|
    v.memory = 20480
    v.cpus = 12
  end

  config.vm.box = "generic/ubuntu2004"
  config.vm.provision "shell", path: "scripts/bootstrap.sh"

end
