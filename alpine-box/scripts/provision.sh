#!/bin/sh
set -eux
adduser -D vagrant
printf 'vagrant\nvagrant\n' | passwd vagrant
mkdir -p /home/vagrant/.ssh && chmod 700 /home/vagrant/.ssh
wget -qO /home/vagrant/.ssh/authorized_keys \
  https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# --- AJOUT : activer community avant d'installer quoi que ce soit ---
sed -i '/^#.*\/community$/s/^#//' /etc/apk/repositories
apk update
# -------------------------------------------------------------------

apk add --no-cache sudo
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant
apk add --no-cache rsync
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
rm -rf /tmp/* /var/cache/apk/*
