# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  config.vm.provider "vmware_desktop" do |v|
    v.memory = 20480
    v.cpus = 12
  end

  config.vm.box = "generic/ubuntu2004"
  config.vm.synced_folder "webapps/", "/home/vagrant/webapps"
  config.vm.provision "shell", privileged: true, path: "bootstrap_root.sh"
  config.vm.provision "shell", privileged: false, path: "bootstrap_vagrant.sh"
  # config.vm.network "public_network", ip: "192.168.174.10"
  # config.vm.network "forwarded_port", guest: 39159, host: 39159

end
