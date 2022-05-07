# cf-for-k8s-on-vm

This project aims to simulate a local development and testing environment that makes use of the familiar Cloud Foundry APIs. 

As the name suggests, this project uses [Vagrant](https://www.vagrantup.com/) to build and manage a VM instance - provided by [VMware (VMware Workstation Player)](https://www.vmware.com/products/workstation-player.html) - and provisions onto the VM instance a set of tools to run CF on. The main components running on the VM instance are:
-  [cf-for-k8s](https://cf-for-k8s.io/) - runs CF on top of Kubernetes
- [kind](https://kind.sigs.k8s.io/) - allows Kubernetes to be ran on Docker container nodes rather than VM nodes. 
- [docker](https://www.docker.com/) - dependency for kind.

## Getting Started
There are a series of steps that you will have to take before we can build the VM. 

1. Install [VMware Workstation Player](https://www.vmware.com/products/workstation-player.html) so we can use it as the VM provider.
2. Install [Vagrant](https://www.vagrantup.com/downloads) so we can use its CLI to build and manage the VM.
3. Install [Vagrant VMware Utility](https://www.vagrantup.com/vmware/downloads) so we can bridge Vagrant with VMWare.
4. After making sure that Vagrant is successfully installed onto your system, run `vagrant plugin install vagrant-vmware-desktop` to install the plugin for VMware.
5. Create a docker repository in the docker account you are using.
6. Clone this repository to your local system and in configs/configs.yml, replace your docker credentials.
7. Run `vagrant up` in the same path where the Vagrantfile is. This should start up the build for the VM and provision the tools to allow cf-for-k8s to run.

## Warning
- The VM is set to start up with 12 cpus and 20GB of RAM. You can configure the starting numbers in the Vagrantfile but I only have success starting up cf-for-k8s using 20GB of RAM.

## Pending Work
- Need to research how to share a VPN network with the VM. Currently, if you are on VPN, the network within the VM is borked and all network calls will fail.
- cf authentication is still not working as expected.