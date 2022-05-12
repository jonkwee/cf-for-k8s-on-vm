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

  config.vm.provider "vmware_desktop" do |v|
    v.memory = 16384
    v.cpus = 8
  end

  config.vm.box = "generic/ubuntu2004"
  config.vm.provision "shell" do |s|
    s.env = {
      "REGISTRY_USERNAME" => docker_config["username"],
      "REGISTRY_PASSWORD" => docker_config["password"],
      "TMP_DIR" => provision_config["tmpPath"],
      "KUBECONFIG" => kube_config["configPath"],
      "CF_ORG" => cf_config["org"],
      "CF_SPACE" => cf_config["space"],
      "CF_DOMAIN" => cf_config["domain"]
    }
    s.path = "scripts/bootstrap.sh"
  end

end
