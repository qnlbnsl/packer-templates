# API URL of your proxmox instace.
variable "proxmox_url" {
  type    = string
  default = ""
}
# Replace with your own path
# Sering this locally on the machine will create performance boost in the getting files ready section.
# Only recommended when wanting to do rapid builds.
variable "iso_file" {
  type    = string
  default = "local:iso/Win10_21H2_English_x64.iso"
}

# Name of the node within the cluster
variable "node" {
  type    = string
  default = "home"
}

# Username for the user to login as in proxmox.
variable "username" {
  type    = string
  default = ""
}

# API Token for the user to login as
variable "token" {
  type    = string
  default = ""
  
}

# If your instace is served locally with self signed certs then set to true. Default is false.
variable "proxmox_skip_tls_verify" {
  type    = string
  default = "true"
}

# Description of the template
variable "template_description" {
  type    = string
  default = "Windows 10 Pro basic template"
}

# Number of cores to assign the builder. Might want to keep this high for faster builds
# Actually does not matter much :|  
variable "vm_cpu_cores" {
  type    = string
  default = "4"
}

# size of the disk 
variable "vm_disk_size" {
  type    = string
  default = "30"
}

# Amount of RAM available to the builder
variable "vm_memory" {
  type    = string
  default = "4096"
}

# Name of the Builder VM that is provisioned
variable "vm_name" {
  type    = string
  default = "Windows"
}


# WinRM Password. MAke sure this matches your passsowrd in the Autounattend.xml file
variable "winrm_password" {
  type    = string
  default = "password"
}

# WinRM Username. MAke sure this matches your passsowrd in the Autounattend.xml file
variable "winrm_username" {
  type    = string
  default = "qnlbnsl"
}

variable "hash" {
  type    = string
  default = ""
}
source "proxmox" "windows" {
  #Load up Autounattend.iso to windows to prep system
  #setus up user accounts, enables winRM, installs chocolatey, and VirtIO
  # VirtIO is required for WinRM detection
  additional_iso_files {
    # which device to load the ISO up as
    device           = "sata3"
    # Self Explanatory. Required only is using iso_url or cd_file
    iso_checksum     = "${var.hash}"
    # If the file already exists on proxmox then use this.
    #iso_file          = "local-network:iso/Autounattend.iso"
    iso_url          = "./Autounattend.iso"
    # Required when using iso_url or cd_file. This is the name of the storage disk that you have on your proxmox node.
    # eg: local, local-lvm, etc...
    iso_storage_pool = "local-network"
    unmount          = true
  }
  # Boot disk drive C
  # Windows install disk D
  # Unattended Disk E
  # This one as F. 
  # If we have more drives to run stuff from then add those scripts accordingly.
  additional_iso_files {
    device  = "sata4"
    iso_file = "local-network:iso/virtio-win.iso"
    unmount = true
  }

  # Lets packer know to use winrm 
  # autounattend.xml is where we enable winRM and setup the users etc....

  communicator = "winrm"
  cores        = "${var.vm_cpu_cores}"
  disks {
    disk_size         = "${var.vm_disk_size}"
    format            = "qcow2"
    # Chosen for speed. This is an SSD and speeds up setup times by almost 5x.
    storage_pool      = "local-lvm"
    storage_pool_type = "directory"
    type              = "sata"
  }
  # Hmmmmmmmm. Not sure what this is supposed to do.
  # http_directory           = "http"
  insecure_skip_tls_verify = "${var.proxmox_skip_tls_verify}"
  iso_file                 = "${var.iso_file}"
  memory                   = "${var.vm_memory}"

  # E1000 is required 
  network_adapters {
    bridge   = "vmbr0"
    model    = "e1000"
    firewall = "1"
  }
  node                 = "${var.node}"
  os                   = "win10"
  token                = "${var.token}"
  proxmox_url          = "https://${var.proxmox_url}/api2/json"
  template_description = "${var.template_description}"
  username             = "${var.username}"
  vm_name              = "${var.vm_name}"
  winrm_insecure       = true
  winrm_password       = "${var.winrm_password}"
  winrm_use_ssl        = true
  winrm_username       = "${var.winrm_username}"
}

build {
  sources = ["source.proxmox.windows"]

  # Installs Chocolately package manager
  provisioner "powershell" {
    script = "provisioningScripts/installChocolatey.ps1"
  }
  # installs 7zip, DirectX 2010, and All VC Redistributables 
  provisioner "powershell" {
    script = "provisioningScripts/installPackages.ps1"
  }
  # setup SSH
  provisioner "powershell" {
    script = "provisioningScripts/setupSSH.ps1"
  }
  # Disable Windows Update
  provisioner "windows-shell" {
    scripts = ["provisioningScripts/disablewinupdate.bat"]
  }
  # disable Hibernate
  provisioner "powershell" {
    scripts = ["provisioningScripts/disable-hibernate.ps1"]
  }

}
