#!/bin/sh
set -eux

ROOT_PASSWORD="${ROOT_PASSWORD:-vagrant}"

#Fichier de réponses pour setup-alpine
cat >/tmp/answers <<'ANSWERS'
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
APKREPOSOPTS="-1"
SSHDOPTS=openssh
NTPOPTS="busybox"
DISKOPTS="-m sys /dev/sda"
ANSWERS

ERASE_DISKS=/dev/sda setup-alpine -e -f /tmp/answers

echo "================= SCHEMA DISQUE ================="
lsblk 2>/dev/null || fdisk -l /dev/sda
echo "================================================="

ROOT_PART=""
for part in /dev/sda[0-9]*; do
    [ -b "$part" ] || continue
    mkdir -p /tmp/probe
    if mount "$part" /tmp/probe 2>/dev/null; then
        if [ -f /tmp/probe/etc/alpine-release ]; then
            ROOT_PART="$part"; umount /tmp/probe || true; break
        fi
        umount /tmp/probe || true
    fi
done
echo ">>> Partition racine détectée : ${ROOT_PART:-AUCUNE}"

if [ -z "$ROOT_PART" ]; then
    echo "ERREUR : racine introuvable (voir le schéma ci-dessus)." >&2
    sleep 30
    exit 1
fi

# Mot de passe root + login SSH root (le temps du provisioning Packer)
mount "$ROOT_PART" /mnt
printf '%s\n%s\n' "$ROOT_PASSWORD" "$ROOT_PASSWORD" | chroot /mnt passwd root
echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config
umount /mnt || true

# Reboot sur le système installé
reboot
