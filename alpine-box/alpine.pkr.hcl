# ============================================================
#  Packer — construit une box Vagrant Alpine pour VirtualBox
#  À PARTIR D'UNE ISO LOCALE déjà téléchargée.
# ============================================================

packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.1.5"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

# ---- Variables À ADAPTER à ton ISO -------------------------
variable "alpine_version" {
  type    = string
  default = "3.22.0" # mets la version de TON ISO
}

# Chemin vers TON ISO locale (relatif à ce fichier, ou chemin absolu).
variable "iso_path" {
  type    = string
  default = "./alpine-virt-3.22.0-x86_64.iso"
}

# sha256 de TON fichier ISO. Calcule-le (voir README) et colle-le ici.
variable "iso_checksum" {
  type    = string
  default = "sha256:REMPLACE_MOI"
}

variable "root_password" {
  type    = string
  default = "vagrant"
}
# ------------------------------------------------------------

source "virtualbox-iso" "alpine" {
  guest_os_type = "Linux26_64" # ou "Linux_64" selon ta version de VirtualBox

  # >>> ON UTILISE TON ISO LOCALE <<<
  iso_url      = var.iso_path
  iso_checksum = var.iso_checksum

  cpus                 = 2
  memory               = 1024
  disk_size            = 8192   # Mo
  hard_drive_interface = "sata" # => disque vu comme /dev/sda

  headless = false # false pour DÉBUGGER (regarder la console), true ensuite

  http_directory = "http" # Packer sert ce dossier en HTTP pendant le boot

  # Principe : on tape le MINIMUM, toute la logique est dans http/install.sh
  boot_wait = "30s"
  boot_command = [
    "root<enter><wait>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5>",
    "wget -qO- http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh | ROOT_PASSWORD=${var.root_password} ash<enter>"
  ]

  # Une fois install.sh terminé, la VM reboote sur le système installé ;
  # Packer s'y connecte alors en SSH (root + mot de passe défini par install.sh).
  ssh_username = "root"
  ssh_password = var.root_password
  ssh_timeout  = "20m"

  shutdown_command = "poweroff"
}

build {
  sources = ["source.virtualbox-iso.alpine"]

  # Provisioning post-install : conventions Vagrant (user vagrant, clé SSH, sudo).
  provisioner "shell" {
    execute_command = "{{ .Vars }} ash '{{ .Path }}'"
    scripts         = ["scripts/provision.sh"]
  }

  # Empaquetage en .box
  post-processor "vagrant" {
    output = "alpine-${var.alpine_version}.box"
  }
}
