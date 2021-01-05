variable "vsphere_server" {
  description = "vsphere server for the environment - EXAMPLE: vcenter01.hosted.local"
  default     = "vc01.corelab.com"
}
variable "vsphere_user" {
  description = "vsphere server for the environment - EXAMPLE: vsphereuser"
  default     = "administrator@corelab.com"
}
variable "vsphere_password" {
  description = "vsphere server password for the environment"
}
variable "vsphere_compute_cluster" {}
variable "vsphere_network" {}
variable "vsphere_datastore" {}
variable "vsphere_datacenter" {
  description = "vsphere server password for the environment"
}
variable "rpm" {
  description = "rpm for software install"
  default     = "installer.rpm"
}
variable "root_password" {
  description = "Root account password"
}
variable "vsphere_virtual_machine_template" {
  description = "VM Template"
}
variable "vsphere_virtual_machine_name" {
  description = "VM Name"
}
