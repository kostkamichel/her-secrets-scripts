#!/bin/bash

# Variables
DISK="/dev/sdb"
PARTITION="${DISK}1"
MOUNT_POINT="/data"
FS_TYPE="ext4"

# Vérifier si le disque existe
if [ ! -b "$DISK" ]; then
    echo "Le disque $DISK n'existe pas."
    exit 1
fi

# Créer une partition si elle n'existe pas
if [ ! -b "$PARTITION" ]; then
    echo "Création de la partition sur $DISK..."
    echo -e "n\np\n1\n\n\nw" | sudo fdisk $DISK
    sudo partprobe $DISK
fi

# Formater la partition si nécessaire
if ! blkid | grep -q "$PARTITION"; then
    echo "Formatage de la partition $PARTITION en $FS_TYPE..."
    sudo mkfs.$FS_TYPE $PARTITION
fi

# Créer le point de montage si nécessaire
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Création du point de montage $MOUNT_POINT..."
    sudo mkdir -p $MOUNT_POINT
fi

# Monter manuellement le disque
echo "Montage du disque..."
sudo mount $PARTITION $MOUNT_POINT

# Récupérer l'UUID du disque
UUID=$(sudo blkid -s UUID -o value $PARTITION)
if [ -z "$UUID" ]; then
    echo "Impossible de récupérer l'UUID de $PARTITION."
    exit 1
fi

# Ajouter au fichier /etc/fstab
if ! grep -q "$UUID" /etc/fstab; then
    echo "Ajout du disque dans /etc/fstab..."
    echo "UUID=$UUID $MOUNT_POINT $FS_TYPE defaults 0 2" | sudo tee -a /etc/fstab
fi

# Vérification du montage automatique
echo "Test du montage automatique..."
sudo mount -a

echo "Le disque a été monté et ajouté à /etc/fstab avec succès."
