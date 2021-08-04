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

variable "connection_name" {
  type    = string
  default = ""
}

locals {
  is_ha           = length(var.gw_object.ha_gw_name) > 0 ? true : false
  connection_name = length(var.connection_name) > 0 ? var.connection_name : "${var.gw_object.gw_name}_to_tgw"
}
