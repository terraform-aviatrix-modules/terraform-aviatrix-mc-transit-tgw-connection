variable "gw_object" {
  description = "Aviatrix Transit Gateway object with all of it's attributes."
}

variable "tunnel_cidrs" {
  type = list(string)
  default = [
    "169.254.101.0/30",
    "169.254.102.0/30",
    "169.254.103.0/30",
    "169.254.104.0/30",
  ]
}

variable "aviatrix_asn" {
  type = number
}

variable "tgw_asn" {
  type = number
}

variable "tgw_id" {
  type = string
}

locals {
  is_ha = var.gw_object.ha_gw_name == null ? false : true
}