# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

current_dir      = File.dirname(File.expand_path(__FILE__))
configs          = YAML.load_file("#{current_dir}/configs/configs.yml")
docker_config    = configs["configs"]["docker"]
provision_config = configs["configs"]["provision"]
kube_config      = configs["configs"]["kube"]

Vagrant.configure("2") do |config|

  config.vm.provider "vmware_desktop" do |v|
    v.memory = 20480
    v.cpus = 8
  end

  config.vm.box = "generic/ubuntu2004"
  config.vm.provision "shell" do |s|
    s.env = {
      "DOCKER_USERNAME" => docker_config["username"],
      "DOCKER_PASSWORD" => docker_config["password"],
      "TMP_DIR" => provision_config["tmpPath"],
      "KUBECONFIG" => kube_config["configPath"]
    }
    s.path = "scripts/bootstrap.sh"
  end

end
