#!/bin/sh
# ============================================================
#  Exécuté DANS le live CD Alpine (via le boot_command de Packer).
#  Installe Alpine sur le disque, puis reboote sur le système installé.
# ============================================================
set -eux

# Mot de passe root transmis par le boot_command (variable d'environnement).
ROOT_PASSWORD="${ROOT_PASSWORD:-vagrant}"

# 1. Fichier de réponses pour setup-alpine (l'équivalent Alpine du preseed Debian).
cat >/tmp/answers <<'EOF'
KEYMAPOPTS="us us"
HOSTNAMEOPTS="alpine"
DEVDOPTS=mdev
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
TIMEZONEOPTS="UTC"
PROXYOPTS=none
APKREPOSOPTS="-1"          # choisit automatiquement un miroir
SSHDOPTS=openssh
NTPOPTS="busybox"
DISKOPTS="-m sys /dev/sda" # installation "system" sur /dev/sda
EOF

# 2. Installation 100% non interactive.
#    -e = mot de passe root vide (pas de prompt) ; ERASE_DISKS évite la confirmation d'effacement.
ERASE_DISKS=/dev/sda setup-alpine -e -f /tmp/answers

# 3. Définir le mot de passe root SUR LE SYSTÈME INSTALLÉ (via chroot).
#    Après une install "sys", setup-disk laisse en général la racine montée sur /mnt.
#    Sinon on la monte. /!\ on suppose /dev/sda3 (layout par défaut avec swap : sda1=boot, sda2=swap, sda3=/).
#    Si SSH échoue après le reboot, vérifie avec `lsblk` et corrige ce device (souvent /dev/sda2 sans swap).
mountpoint -q /mnt || mount /dev/sda3 /mnt
printf '%s\n%s\n' "$ROOT_PASSWORD" "$ROOT_PASSWORD" | chroot /mnt passwd root

# 4. Autoriser temporairement le login root en SSH (le temps du provisioning Packer).
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /mnt/etc/ssh/sshd_config

umount /mnt 2>/dev/null || true

# 5. Reboot sur le système fraîchement installé.
reboot
