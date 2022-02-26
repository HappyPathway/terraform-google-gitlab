#!/bin/bash
# test
function gitadmin {
    echo "Adding gitadmin user"
    useradd -m gitadmin
    echo "Setting password for gitadmin user"
    echo "${password}" | passwd --stdin gitadmin || echo -e "${password}\n${password}" | (passwd gitadmin)

    echo "Adding gitadmin user to sudoers file"
    echo 'gitadmin ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers > /dev/null
    echo "Adding gitadmin to sudo group"
    usermod -aG sudo gitadmin
}

function configure_ssl {
    # /opt/gitlab/home/ssl
    cat <<EOF > /opt/gitlab/home/ssl/${hostname}.key
${ssl_key} 
EOF
    cat <<EOF > /opt/gitlab/home/ssl/${hostname}.crt 
${ssl_cert}
EOF
}

function reconfigure_ssh {
    echo "Port 2222" >> /etc/ssh/sshd_config;
    echo "ListenAddress 0.0.0.0:2222" >> /etc/ssh/sshd_config;
    service ssh restart;
    systemctl restart sshd.service
}

function disk_setup {
    mkdir /opt/gitlab
    xfs_admin -L gitlab /dev/sdb || echo 
    echo 'LABEL=gitlab		/opt/gitlab xfs		defaults	0 0' >> /etc/fstab || echo
    mount -a
}

function docker_install {
    echo "Installing Docker"
    apt-get update
    sudo apt-get remove docker docker-engine docker.io containerd runc
    sudo apt-get install -y\
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
}

function directories {
    echo "Preparing Directories"
    mkdir -p /opt/gitlab/home/config
    mkdir -p /opt/gitlab/home/logs
    mkdir -p /opt/gitlab/home/data
    mkdir -p /opt/gitlab/home/ssl
}

function setup_sendgrid_test {
    echo "Setting up Sendgrid Test"
    cat <<EOF >/usr/local/bin/sendgrid-test
${sendgrid_test}
EOF
    chmod +x /usr/local/bin/sendgrid-test
}

function docker_compose_setup {
    echo "Setting up Docker Compose File"
    cat <<EOF >/etc/docker-compose.yaml
${docker_compose}
EOF
}

function docker_compose {
    echo "Running Docker Compose"
    $(docker-compose -f /etc/docker-compose.yaml up) >/var/log/docker.log 2>&1
}

disk_setup || echo "Could not setup disk"
reconfigure_ssh || echo "Could not reconfigure SSH"
# gitadmin || echo "Could not setup gitadmin user"
directories || echo "Could not setup proper directories"
configure_ssl || echo "Could not configure SSL"
docker_install || echo "Could not install Docker"
docker_compose_setup || echo "Could not setup docker-compose"
docker_compose || echo "Could not run docker-compose"
setup_sendgrid_test || echo "Could not setup sendgrid-test"
