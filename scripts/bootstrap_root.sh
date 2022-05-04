#!/bin/sh

add_repositories()
{
    echo "Adding Repositories..."
    cf_repo
    docker_repo
}

cf_repo()
{
    wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
    echo "deb https://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
}

docker_repo()
{
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}

update_os()
{
    echo "Upgrading all packages..."
    sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove
    echo "Upgrading packages complete..."
}

setup_dependencies()
{
    YTT_VERSION="v0.40.1"
    KAPP_VERSION="v0.46.0"
    KIND_VERSION="v0.12.0"
    KUBE_VERSION="v1.19.0"
    BOSH_VERSION="6.4.17"

    if [ ! -f "/usr/local/bin/ytt" ]; then
        echo "Downloading ytt version ${YTT_VERSION}..."
        curl -Lo ./ytt https://github.com/vmware-tanzu/carvel-ytt/releases/download/${YTT_VERSION}/ytt-linux-amd64
        sudo mv ./ytt /usr/local/bin
        sudo chmod +x /usr/local/bin/ytt
    fi

    if [ ! -f "/usr/local/bin/kapp" ]; then
        echo "Downloading kapp version ${KAPP_VERSION}..."
        curl -Lo ./kapp https://github.com/vmware-tanzu/carvel-kapp/releases/download/${KAPP_VERSION}/kapp-linux-amd64
        sudo mv ./kapp /usr/local/bin
        sudo chmod +x /usr/local/bin/kapp
    fi

    if [ ! -f "/usr/local/bin/kind" ]; then
        echo "Downloading kind version ${KIND_VERSION}..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
        sudo mv ./kind /usr/local/bin
        sudo chmod +x /usr/local/bin/kind
    fi

    if [ ! -f "/usr/local/bin/kubectl" ]; then
        echo "Downloading kubectl version ${KUBE_VERSION}..."
        curl -Lo ./kubectl https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl
        sudo mv ./kubectl /usr/local/bin
        sudo chmod +x /usr/local/bin/kubectl
    fi


    if [ ! -f "/usr/local/bin/bosh" ]; then
        echo "Downloading bosh version ${BOSH_VERSION}..."
        curl -Lo ./bosh https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-${BOSH_VERSION}-linux-amd64
        sudo mv ./bosh /usr/local/bin
        sudo chmod +x /usr/local/bin/bosh
    fi

    echo "Downloading cf7-cli..."
    sudo apt-get -y install cf7-cli

    echo "Downloading docker..."
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker vagrant
}


add_repositories
update_os
setup_dependencies