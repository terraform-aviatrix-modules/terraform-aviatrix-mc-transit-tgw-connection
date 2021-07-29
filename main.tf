resource "aws_customer_gateway" "transit1a" {
  bgp_asn    = var.aviatrix_asn
  ip_address = var.gw.eip
  type       = "ipsec.1"

  tags = {
    Name = var.gw.gw_name
  }
}

resource "aws_customer_gateway" "transit1b" {
  bgp_asn    = var.aviatrix_asn
  ip_address = var.gw.ha_eip
  type       = "ipsec.1"

  tags = {
    Name = var.gw.ha_gw_name
  }
}

resource "random_password" "psk_transit_1tunnel1" {
  length  = 64
  special = false
}

resource "random_password" "psk_transit_1tunnel2" {
  length  = 64
  special = false
}

resource "aws_vpn_connection" "transit1a" {
  customer_gateway_id = aws_customer_gateway.transit1a.id
  transit_gateway_id  = var.tgw_id
  type                = aws_customer_gateway.transit1a.type

  tunnel1_inside_cidr   = var.tunnel_cidrs[0]
  tunnel2_inside_cidr   = var.tunnel_cidrs[2]
  tunnel1_preshared_key = random_password.psk_transit_1tunnel1.result
  tunnel2_preshared_key = random_password.psk_transit_1tunnel2.result
}

resource "aws_vpn_connection" "transit1b" {
  customer_gateway_id = aws_customer_gateway.transit1b.id
  transit_gateway_id  = var.tgw_id
  type                = aws_customer_gateway.transit1b.type

  tunnel1_inside_cidr   = var.tunnel_cidrs[1]
  tunnel2_inside_cidr   = var.tunnel_cidrs[3]
  tunnel1_preshared_key = random_password.psk_transit_1tunnel1.result
  tunnel2_preshared_key = random_password.psk_transit_1tunnel2.result
}

resource "aviatrix_transit_external_device_conn" "transit1a_to_tgw" {
  vpc_id             = var.gw.vpc_id
  connection_name    = "transit1_to_tgw_a"
  gw_name            = var.gw.gw_name
  connection_type    = "bgp"
  bgp_local_as_num   = var.aviatrix_asn
  bgp_remote_as_num  = var.tgw_asn
  remote_gateway_ip  = "${aws_vpn_connection.transit1a.tunnel1_address},${aws_vpn_connection.transit1b.tunnel1_address}"
  local_tunnel_cidr  = "${cidrhost(var.tunnel_cidrs[0], 2)}/30,${cidrhost(var.tunnel_cidrs[1], 2)}/30"
  remote_tunnel_cidr = "${cidrhost(var.tunnel_cidrs[0], 1)}/30,${cidrhost(var.tunnel_cidrs[1], 1)}/30"
  pre_shared_key     = random_password.psk_transit_1tunnel1.result
}

resource "aviatrix_transit_external_device_conn" "transit1b_to_tgw" {
  vpc_id             = var.gw.vpc_id
  connection_name    = "transit1_to_tgw_b"
  gw_name            = var.gw.gw_name
  connection_type    = "bgp"
  bgp_local_as_num   = var.aviatrix_asn
  bgp_remote_as_num  = var.tgw_asn
  remote_gateway_ip  = "${aws_vpn_connection.transit1a.tunnel2_address},${aws_vpn_connection.transit1b.tunnel2_address}"
  local_tunnel_cidr  = "${cidrhost(var.tunnel_cidrs[2], 2)}/30,${cidrhost(var.tunnel_cidrs[3], 2)}/30"
  remote_tunnel_cidr = "${cidrhost(var.tunnel_cidrs[2], 1)}/30,${cidrhost(var.tunnel_cidrs[3], 1)}/30"
  pre_shared_key     = random_password.psk_transit_1tunnel2.result
}