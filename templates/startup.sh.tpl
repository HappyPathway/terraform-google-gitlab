
#!/bin/bash
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
}

function docker_compose_setup {
    echo "Setting up Docker Compose File"
    cat <<EOF >/etc/docker-compose.yaml
    ${docker_compose}
    EOF
}

function docker_compose {
    echo "Running Docker Compose"
    docker-compose -d -f /etc/docker-compose.yaml up
}


gitadmin || echo "Could not setup gitadmin user"
docker_install || echo "Could not install Docker"
directories || echo "Could not setup proper directories"
docker_compose_setup || echo "Could not setup docker-compose"
docker_compose || echo "Could not run docker-compose"