variable "proxmox_endpoint" {
  type = string
  description = "The endpoint of the Proxmox VE API"
}

variable "proxmox_username" {
  type = string
  description = "The username of the Proxmox VE API"
}

variable "proxmox_password" {
  type = string
  description = "The password of the Proxmox VE API"
}

variable "proxmox_insecure" {
  type = bool
  description = "Whether to allow insecure connections to the Proxmox VE API"
}

variable "proxmox_content_type" {
  type = string
  description = "The content type of the Proxmox VE API"
}

variable "proxmox_datastore_id" {
  type = string
  description = "The datastore ID of the Proxmox VE API"
}

variable "proxmox_node_name" {
  type = string
  description = "The node name of the Proxmox VE API"
}

variable "proxmox_vm_id" {
  type = number
  description = "The VM ID of the Proxmox VE API"
}

variable "proxmox_vm_name" {
  type = string
  description = "The name of the Proxmox VE API"
}

variable "proxmox_cpu_type" {
  type = string
  description = "The type of the CPU of the Proxmox VE API"
}

variable "proxmox_disk_file_format" {
  type = string
  description = "The file format of the disk of the Proxmox VE API"
}

variable "proxmox_disk_interface" {
  type = string
  description = "The interface of the disk of the Proxmox VE API"
}

variable "proxmox_disk_size" {
  type = number
  description = "The size of the disk of the Proxmox VE API"
}

variable "proxmox_network_bridge" {
  type = string
  description = "The bridge of the network of the Proxmox VE API"
}
variable "proxmox_cpu_cores" {
  type = number
  description = "The number of cores of the CPU of the Proxmox VE API"
}

