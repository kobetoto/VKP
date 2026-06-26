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
  default = "3.24.1" 
}

variable "iso_path" {
  type    = string
  default = "./alpine-virt-3.24.1-x86_64.iso"
}

# sha256 de TON fichier ISO. Calcule-le (voir README) et colle-le ici.
variable "iso_checksum" {
  type    = string
  default = "sha256:e73a6241bd5f3c5c2d4d38c02cc52c378c0415a7c888bd292066bf36e0f41a39"
}

variable "root_password" {
  type    = string
  default = "toto1234a+"
}
# ------------------------------------------------------------

source "virtualbox-iso" "alpine" {
  guest_os_type = "Linux_64"

  iso_url      = var.iso_path
  iso_checksum = var.iso_checksum

  cpus                 = 2
  memory               = 1024
  disk_size            = 8192   # Mo
  hard_drive_interface = "sata" #  disque vu comme /dev/sda

  headless = false # false pour DÉBUGGER (regarder la console), true ensuite

  http_directory = "http" # Packer sert ce dossier en HTTP pendant le boot

  boot_wait = "30s"
  boot_command = [
    "root<enter><wait>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5>",
    "wget -qO- http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh | ROOT_PASSWORD=${var.root_password} ash<enter>"
  ]

  # Une fois install.sh terminé, la VM reboote sur le système installé
  # Packer s'y connecte alors en SSH (root + mot de passe défini par install.sh)
  ssh_username = "root"
  ssh_password = var.root_password
  ssh_timeout  = "20m"

  shutdown_command = "poweroff"
}

build {
  sources = ["source.virtualbox-iso.alpine"]

  # Provisioning post-install : conventions Vagrant (user vagrant, clé SSH, sudo)
  provisioner "shell" {
    execute_command = "{{ .Vars }} ash '{{ .Path }}'"
    scripts         = ["scripts/provision.sh"]
  }

  # Empaquetage en .box
  post-processor "vagrant" {
    output = "alpine-${var.alpine_version}.box"
  }
}
