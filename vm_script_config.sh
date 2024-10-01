#!/bin/bash

# ===========================
# Variables
# ===========================
DISK="/dev/sdb"
PARTITION="${DISK}1"
MOUNT_POINT="/data"
FS_TYPE="ext4"
DOCKER_DIR="/etc/docker"
DAEMON_JSON="$DOCKER_DIR/daemon.json"
DOCKER_INSTALL_SCRIPT="get-docker.sh"
AZURE_CLI_INSTALL_URL="https://aka.ms/InstallAzureCLIDeb"

# ===========================
# Functions
# ===========================
function check_disk {
    if [ ! -b "$DISK" ]; then
        echo "Le disque $DISK n'existe pas."
        exit 1
    fi
}

function create_partition {
    if [ ! -b "$PARTITION" ]; then
        echo "Création de la partition sur $DISK..."
        sudo parted $DISK --script mklabel gpt mkpart ${FS_TYPE}part $FS_TYPE 0% 100%
        sudo partprobe $DISK
    fi
}

function format_partition {
    if ! blkid | grep -q "$PARTITION"; then
        echo "Formatage de la partition $PARTITION en $FS_TYPE..."
        sudo mkfs.$FS_TYPE $PARTITION
    fi
}

function create_mount_point {
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Création du point de montage $MOUNT_POINT..."
        sudo mkdir -p $MOUNT_POINT
    fi
}

function mount_partition {
    echo "Montage du disque..."
    sudo mount $PARTITION $MOUNT_POINT
}

function add_to_fstab {
    UUID=$(sudo blkid -s UUID -o value $PARTITION)
    if [ -z "$UUID" ]; then
        echo "Impossible de récupérer l'UUID de $PARTITION."
        exit 1
    fi

    if ! grep -q "$UUID" /etc/fstab; then
        echo "Ajout du disque dans /etc/fstab..."
        echo "UUID=$UUID $MOUNT_POINT $FS_TYPE defaults 0 2" | sudo tee -a /etc/fstab
    fi

    echo "Vérification du montage automatique..."
    sudo mount -a
}

function configure_docker {
    echo "Création du répertoire Docker et configuration du daemon..."
    sudo mkdir -p $DOCKER_DIR
    cat <<EOF | sudo tee $DAEMON_JSON
{
    "data-root": "/data/docker"
}
EOF
}

function install_docker {
    echo "Téléchargement du script d'installation de Docker..."
    curl -fsSL https://get.docker.com -o $DOCKER_INSTALL_SCRIPT

    echo "Installation de Docker..."
    sudo sh $DOCKER_INSTALL_SCRIPT
}

function add_user_to_docker_group {
    echo "Ajout de l'utilisateur au groupe Docker..."
    sudo usermod -aG docker "${data.azurerm_key_vault_secret.vm_admin_username.value}"
    newgrp docker
}

function install_azure_cli {
    echo "Installation de l'Azure CLI..."
    curl -sL $AZURE_CLI_INSTALL_URL | sudo bash
}

# ===========================
# Main Script Execution
# ===========================
check_disk
create_partition
format_partition
create_mount_point
mount_partition
add_to_fstab
configure_docker
install_docker
add_user_to_docker_group
install_azure_cli

echo "Script exécuté avec succès !"
