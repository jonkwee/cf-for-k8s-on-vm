# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

current_dir      = File.dirname(File.expand_path(__FILE__))
configs          = YAML.load_file("#{current_dir}/configs/configs.yml")
docker_config    = configs["configs"]["docker"]
provision_config = configs["configs"]["provision"]
kube_config      = configs["configs"]["kube"]
cf_config        = configs["configs"]["cf"]

Vagrant.configure("2") do |config|

  config.vm.define "local_cf"

  config.vm.provider "vmware_desktop" do |v|
    v.memory = 16384
    v.cpus = 8
  end
  config.vm.synced_folder "playbooks/", "/home/vagrant/playbooks", type: "rsync"
  config.vm.synced_folder "clusters/", "/home/vagrant/cluster_configs", type: "rsync"
  config.vm.synced_folder "credentials/", "/home/vagrant/credentials", type: "rsync"
  config.vm.synced_folder "shared/", "/vagrant"
  config.vm.box = "generic/ubuntu2004"

  # Port forwarding for RabbitMQ Management UI
  config.vm.network "forwarded_port", guest: 15672, host: 15672
  # Port forwarding for Vault
  config.vm.network "forwarded_port", guest: 8200, host: 8200
  
  $install_ansible_script = <<-SCRIPT
  sudo apt update
  sudo apt install software-properties-common
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt -y install ansible
  ansible-galaxy collection install community.general
  SCRIPT

  config.vm.provision "shell", inline: $install_ansible_script

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "bootstrap.yml"
    ansible.provisioning_path = "/home/vagrant/playbooks"
    ansible.extra_vars = {
      KUBECONFIG: kube_config["configPath"],
      TMP_DIR: provision_config["tmpPath"],
      CONFIG_DIR: provision_config["configPath"],
      CREDENTIAL_DIR: provision_config["credentialPath"],
      REGISTRY_USERNAME: docker_config["username"],
      REGISTRY_PASSWORD: docker_config["password"],
      CF_ORG: cf_config["org"],
      CF_SPACE: cf_config["space"],
      CF_DOMAIN: cf_config["domain"]
    }
  end

end
