variable "gw_object" {
  description = "Aviatrix Transit Gateway object with all of it's attributes."
}

variable "vpc_object" {
  description = "Aviatrix VPC object for the transit VPC with all of it's attributes."
  default     = { subnets : [] }
  nullable    = false
}

variable "tunnel_cidrs" {
  type     = list(string)
  default  = []
  nullable = false
}

variable "aviatrix_asn" {
  description = "The ASN of the Aviatrix transit gateway"
  type        = number
}

variable "tgw_asn" {
  description = "The ASN configured on the TGW"
  type        = number
}

variable "tgw_id" {
  description = "The ID of the TGW"
  type        = string
}

variable "tgw_cidr_blocks" {
  description = "CIDR blocks assigned to the TGW"
  type        = list(string)
  default     = []
  nullable    = false
}


variable "connection_name" {
  description = "Name to use to create the S2C connections on the Aviatrix gateways"
  type        = string
  default     = ""
}

variable "enable_learned_cidrs_approval" {
  description = "Set to true to enable learned CIDR's approval"
  default     = false
}

variable "approved_cidrs" {
  description = "A list of approved CIDRs for when enable_learned_cidrs_approval is true."
  default     = null
}

variable "aws_vpn_tunnel_name" {
  description = "Name of AWS S2S VPN tunnel."
  type        = string
  default     = "-"
}

variable "aws_vpn_ha_tunnel_name" {
  description = "Name of AWS S2S VPN high availability tunnel."
  type        = string
  default     = "-"
}

variable "connection_type" {
  description = "Determines whether this will be built as a GRE or IPSEC connection."
  type        = string
  default     = "Ipsec"

  validation {
    condition     = contains(["ipsec", "gre"], lower(var.connection_type))
    error_message = "Invalid connection type. Choose IPSEC or GRE."
  }
}

locals {
  is_ha           = var.gw_object.ha_gw_size != null
  connection_name = length(var.connection_name) > 0 ? var.connection_name : "${var.gw_object.gw_name}_to_tgw"
  connection_type = lower(var.connection_type)

  default_tunnel_cidrs = ( #Use /30 for ipsec and /29 for GRE
    local.connection_type == "ipsec" ?
    [
      "169.254.101.0/30",
      "169.254.102.0/30",
      "169.254.103.0/30",
      "169.254.104.0/30",
    ]
    :
    [
      "169.254.101.0/29",
      "169.254.102.0/29",
      "169.254.103.0/29",
      "169.254.104.0/29",
    ]
  )

  #Use default_tunnel_cidrs if none are explicitly provided or provided cidrs in var.tunnel_cidrs if provided.
  tunnel_cidrs = length(var.tunnel_cidrs) > 0 ? var.tunnel_cidrs : local.default_tunnel_cidrs

  route_object = local.connection_type == "gre" ? merge([for rtb in var.vpc_object.route_tables : {
    for cidr in var.tgw_cidr_blocks : join("-", [rtb, cidr]) => { "cidr" : cidr, "rtb" : rtb }
    }
  ]...) : {}

  vpc_attachment_subnets = [for subnet in var.vpc_object.subnets.* : subnet.subnet_id if length(regexall("Public-gateway-and-firewall-mgmt", subnet.name)) > 0]
}
