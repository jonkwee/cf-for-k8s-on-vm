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


append_additional_install_values()
{
    echo "Appending additional CF Installation values..."
    {
        echo 'add_metrics_server_components: true'
        echo 'enable_automount_service_account_token: true'
        echo 'metrics_server_prefer_internal_kubelet_address: true'
        echo 'remove_resource_requirements: true'
        echo 'load_balancer: '
        echo '  enable: false'
        echo 'use_first_party_jwt_tokens: true'
    } >> ${TMP_DIR}/cf-values.yml
}

append_dockerhub_config()
{
    echo "Appending Dockerhub config..."
    {
        printf "app_registry:\n"
        printf "$2 hostname: https://index.docker.io/v1/\n"
        printf "$2 repository_prefix: $REGISTRY_USERNAME\n"
        printf "$2 username: $REGISTRY_USERNAME\n"
        printf "$2 password: $REGISTRY_PASSWORD"
    } >> ${TMP_DIR}/cf-values.yml
}

export_env_variables()
{
    if ! grep -q "KUBECONFIG" /etc/environment; then
        printf "\nKUBECONFIG=$KUBECONFIG" >> /etc/environment
    fi
    if ! grep -q "TMP_DIR" /etc/environment; then
        printf "\nTMP_DIR=$TMP_DIR" >> /etc/environment
    fi
    if ! grep -q "REGISTRY_USERNAME" /etc/environment; then
        printf "\nREGISTRY_USERNAME=$REGISTRY_USERNAME" >> /etc/environment
    fi
    if ! grep -q "REGISTRY_PASSWORD" /etc/environment; then
        printf "\nREGISTRY_PASSWORD=$REGISTRY_PASSWORD" >> /etc/environment
    fi
}

setup_cf()
{
    cf api --skip-ssl-validation https://api.vcap.me
    cf auth admin "$(grep cf_admin_password ${TMP_DIR}/cf-values.yml | cut -d" " -f2)"
    cf create-org $CF_ORG
    cf create-space -o $CF_ORG $CF_SPACE
    cf target -o $CF_ORG -s $CF_SPACE
}

cf_for_k8s_setup()
{
    export_env_variables
    if [ ! -d "/home/vagrant/cf-for-k8s" ]; then
        echo "Cloning cf-for-k8s..."
        git clone https://github.com/jonkwee/cf-for-k8s.git -b main
        cd cf-for-k8s    
        mkdir -p ${TMP_DIR}
    else
        cd cf-for-k8s 
    fi

    cluster=$(kind get clusters)
    if [ ! "${cluster}" = "kind" ]; then
        echo "Creating kind cluster..."
        kind create cluster --config=./deploy/kind/cluster.yml --image kindest/node:v1.20.2
    fi

    if [ ! -f "${TMP_DIR}/cf-values.yml" ]; then
        # Generate CF Installation Values
        echo "Generate CF Installation values..."
        ./hack/generate-values.sh -d ${CF_DOMAIN} > ${TMP_DIR}/cf-values.yml
        append_additional_install_values
        append_dockerhub_config
    fi

    if [ ! -f "${TMP_DIR}/cf-for-k8s-rendered.yml" ]; then
        echo "Generate raw K8s config..."
        ytt -f config -f ${TMP_DIR}/cf-values.yml > ${TMP_DIR}/cf-for-k8s-rendered.yml
    fi

    echo "Deploying..."
    kapp deploy -a cf -f ${TMP_DIR}/cf-for-k8s-rendered.yml -y

    setup_cf
}

add_repositories
update_os
setup_dependencies
cf_for_k8s_setup