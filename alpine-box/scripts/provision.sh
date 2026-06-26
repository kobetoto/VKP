#!/bin/sh
# ============================================================
#  Exécuté en SSH après le reboot (par le provisioner Packer).
#  Applique les conventions Vagrant pour rendre la box utilisable.
#  NB : pas de Docker ici -> il s'installe dans le Vagrantfile du projet
#       (modèle en deux couches : box générique + projet spécifique).
# ============================================================
set -eux

# 1. Utilisateur vagrant + mot de passe conventionnel.
adduser -D vagrant
printf 'vagrant\nvagrant\n' | passwd vagrant

# 2. Clé publique "insecure" officielle de Vagrant.
#    Vagrant la reconnaît et la remplace par une clé unique au 1er `vagrant up`.
#    (Si l'URL renvoie une 404, récupère le fichier dans le dépôt hashicorp/vagrant, dossier keys/.)
mkdir -p /home/vagrant/.ssh && chmod 700 /home/vagrant/.ssh
wget -qO /home/vagrant/.ssh/authorized_keys \
  https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# 3. sudo sans mot de passe pour vagrant.
apk add --no-cache sudo
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant

# 4. rsync : Vagrant l'utilise pour les dossiers partagés (vboxsf marche mal sous Alpine).
apk add --no-cache rsync

# 5. Durcissement : root ne pourra plus se logger en SSH (vagrant existe désormais).
#    La session SSH en cours reste ouverte, donc ça ne casse pas le build.
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# 6. Nettoyage (réduit la taille de la box).
rm -rf /tmp/* /var/cache/apk/*
