#!/bin/bash

# Création du répertoire Docker et configuration du daemon
echo "Création du répertoire Docker et configuration du daemon..."
sudo bash -c 'mkdir -p /etc/docker && \
cat <<EOF > /etc/docker/daemon.json
{
    "data-root": "/data/docker"
}
EOF'

# Installation de Docker
echo "Téléchargement du script d'installation de Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh

echo "Installation de Docker..."
sudo sh get-docker.sh

# Ajout de l'utilisateur au groupe Docker
echo "Ajout de l'utilisateur au groupe Docker..."
sudo usermod -aG docker "${data.azurerm_key_vault_secret.vm_admin_username.value}"

# Installation de l'Azure CLI
echo "Installation de l'Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Script exécuté avec succès !"
