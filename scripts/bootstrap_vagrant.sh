#!/bin/sh

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
    source ../configs/docker_credentials.properties
    {
        echo 'app_registry:'
        echo '  hostname: https://index.docker.io/v1/'
        echo '  repository_prefix: "${docker_username}"'
        echo '  username: "${docker_username}"'
        echo '  password: "${docker_password}"'
    } >> ${TMP_DIR}/cf-values.yml
}

export_env_variables()
{
    export KUBECONFIG="/home/vagrant/tmp/kube.config"
}

setup_cf()
{
    cf api --skip-ssl-validation https://api.vcap.me
    cf auth admin "$(grep cf_admin_password ${TMP_DIR}/cf-values.yml | cut -d" " -f2)"
    cf create-org connected-capture
    cf create-space -o connected-capture cc-dev
    cf target -o connected-capture -s cc-dev
}

cf_for_k8s_setup()
{
    export_env_variables
    if [ ! -d "/home/vagrant/cf-for-k8s" ]; then
        echo "Cloning cf-for-k8s..."
        git clone https://github.com/cloudfoundry/cf-for-k8s.git -b main
        cd cf-for-k8s    
        mkdir -p ${TMP_DIR}
    else
        cd cf-for-k8s 
    fi

    if [ ! -f "${TMP_DIR}/cf-values.yml" ]; then
        # Generate CF Installation Values
        echo "Generate CF Installation values..."
        CF_DOMAIN="vcap.me"
        ./hack/generate-values.sh -d ${CF_DOMAIN} > ${TMP_DIR}/cf-values.yml
        append_additional_install_values
        append_dockerhub_config
    fi

    if [ ! -f "${TMP_DIR}/cf-for-k8s-rendered.yml" ]; then
        echo "Generate raw K8s config..."
        ytt -f config -f ${TMP_DIR}/cf-values.yml > ${TMP_DIR}/cf-for-k8s-rendered.yml
    fi

    cluster=$(kind get clusters)
    if [ ! "${cluster}" = "kind" ]; then
        echo "Creating kind cluster..."
        kind create cluster --config=./deploy/kind/cluster.yml --image kindest/node:v1.20.2
    fi

    # echo "Deploying..."
    # kapp deploy -a cf -f ${TMP_DIR}/cf-for-k8s-rendered.yml -y

    # setup_cf
}

TMP_DIR=/home/vagrant/tmp

cf_for_k8s_setup