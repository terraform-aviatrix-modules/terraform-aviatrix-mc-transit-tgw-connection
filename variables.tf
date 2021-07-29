variable "gw" {

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
