#IPSEC related resources
moved {
  from = aws_customer_gateway.transit_gw
  to   = aws_customer_gateway.transit_gw[0]
}

resource "aws_customer_gateway" "transit_gw" {
  count      = local.connection_type == "ipsec" ? 1 : 0
  bgp_asn    = var.aviatrix_asn
  ip_address = var.gw_object.public_ip
  type       = "ipsec.1"

  tags = {
    Name = var.gw_object.gw_name
  }
}

resource "aws_customer_gateway" "transit_ha_gw" {
  count      = local.is_ha && local.connection_type == "ipsec" ? 1 : 0
  bgp_asn    = var.aviatrix_asn
  ip_address = var.gw_object.ha_public_ip
  type       = "ipsec.1"

  tags = {
    Name = var.gw_object.ha_gw_name
  }
}

resource "random_password" "psk" {
  count   = local.connection_type == "ipsec" ? 2 : 0
  length  = 64
  special = false
  numeric = false #We need to make sure we don't need numbers, because of the edge case of the psk starting with 0. This is not supported in aws_vpn_connection
}

moved {
  from = aws_vpn_connection.transit_gw
  to   = aws_vpn_connection.transit_gw[0]
}

resource "aws_vpn_connection" "transit_gw" {
  count               = local.connection_type == "ipsec" ? 1 : 0
  customer_gateway_id = aws_customer_gateway.transit_gw[0].id
  transit_gateway_id  = var.tgw_id
  type                = aws_customer_gateway.transit_gw[0].type

  tunnel1_inside_cidr   = local.tunnel_cidrs[0]
  tunnel2_inside_cidr   = local.tunnel_cidrs[1]
  tunnel1_preshared_key = random_password.psk[0].result
  tunnel2_preshared_key = random_password.psk[1].result
  tags                  = { Name = "${var.aws_vpn_tunnel_name}" }
}

resource "aws_vpn_connection" "transit_ha_gw" {
  count               = local.is_ha && local.connection_type == "ipsec" ? 1 : 0
  customer_gateway_id = aws_customer_gateway.transit_ha_gw[0].id
  transit_gateway_id  = var.tgw_id
  type                = aws_customer_gateway.transit_ha_gw[0].type

  tunnel1_inside_cidr   = local.tunnel_cidrs[2]
  tunnel2_inside_cidr   = local.tunnel_cidrs[3]
  tunnel1_preshared_key = random_password.psk[0].result
  tunnel2_preshared_key = random_password.psk[1].result
  tags                  = { Name = "${var.aws_vpn_ha_tunnel_name}" }
}

moved {
  from = aviatrix_transit_external_device_conn.tunnel1_to_tgw
  to   = aviatrix_transit_external_device_conn.ipsec_tunnel1_to_tgw[0]
}

resource "aviatrix_transit_external_device_conn" "ipsec_tunnel1_to_tgw" {
  count                         = local.connection_type == "ipsec" ? 1 : 0
  vpc_id                        = var.gw_object.vpc_id
  connection_name               = "${local.connection_name}_a"
  gw_name                       = var.gw_object.gw_name
  connection_type               = "bgp"
  bgp_local_as_num              = var.aviatrix_asn
  bgp_remote_as_num             = var.tgw_asn
  remote_gateway_ip             = local.is_ha ? "${aws_vpn_connection.transit_gw[0].tunnel1_address},${aws_vpn_connection.transit_ha_gw[0].tunnel1_address}" : aws_vpn_connection.transit_gw[0].tunnel1_address
  local_tunnel_cidr             = local.is_ha ? format("%s/30,%s/30", cidrhost(local.tunnel_cidrs[0], 2), cidrhost(local.tunnel_cidrs[2], 2)) : format("%s/30", cidrhost(local.tunnel_cidrs[0], 2))
  remote_tunnel_cidr            = local.is_ha ? format("%s/30,%s/30", cidrhost(local.tunnel_cidrs[0], 1), cidrhost(local.tunnel_cidrs[2], 1)) : format("%s/30", cidrhost(local.tunnel_cidrs[0], 1))
  pre_shared_key                = random_password.psk[0].result
  enable_learned_cidrs_approval = var.enable_learned_cidrs_approval
  approved_cidrs                = var.approved_cidrs
}

moved {
  from = aviatrix_transit_external_device_conn.tunnel2_to_tgw
  to   = aviatrix_transit_external_device_conn.ipsec_tunnel2_to_tgw[0]
}

resource "aviatrix_transit_external_device_conn" "ipsec_tunnel2_to_tgw" {
  count                         = local.connection_type == "ipsec" ? 1 : 0
  vpc_id                        = var.gw_object.vpc_id
  connection_name               = "${local.connection_name}_b"
  gw_name                       = var.gw_object.gw_name
  connection_type               = "bgp"
  bgp_local_as_num              = var.aviatrix_asn
  bgp_remote_as_num             = var.tgw_asn
  remote_gateway_ip             = local.is_ha ? "${aws_vpn_connection.transit_gw[0].tunnel2_address},${aws_vpn_connection.transit_ha_gw[0].tunnel2_address}" : aws_vpn_connection.transit_gw[0].tunnel2_address
  local_tunnel_cidr             = local.is_ha ? format("%s/30,%s/30", cidrhost(local.tunnel_cidrs[1], 2), cidrhost(local.tunnel_cidrs[3], 2)) : format("%s/30", cidrhost(local.tunnel_cidrs[1], 2))
  remote_tunnel_cidr            = local.is_ha ? format("%s/30,%s/30", cidrhost(local.tunnel_cidrs[1], 1), cidrhost(local.tunnel_cidrs[3], 1)) : format("%s/30", cidrhost(local.tunnel_cidrs[1], 1))
  pre_shared_key                = random_password.psk[1].result
  enable_learned_cidrs_approval = var.enable_learned_cidrs_approval
  approved_cidrs                = var.approved_cidrs
}

#GRE Related resources
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_to_avx_transit_vpc" {
  count              = local.connection_type == "gre" ? 1 : 0
  subnet_ids         = local.vpc_attachment_subnets
  transit_gateway_id = var.tgw_id
  vpc_id             = var.vpc_object.vpc_id
  tags = {
    "Name" = format("%s-VPC", var.vpc_object.name)
  }
}

resource "aws_ec2_transit_gateway_connect" "attachment" {
  count                   = local.connection_type == "gre" ? 1 : 0
  transport_attachment_id = aws_ec2_transit_gateway_vpc_attachment.tgw_to_avx_transit_vpc[0].id
  transit_gateway_id      = var.tgw_id
  tags = {
    "Name" = format("%s-Connect", var.vpc_object.name)
  }
}

resource "aws_route" "route_to_tgw_cidr_block" {
  for_each = local.route_object

  route_table_id         = each.value.rtb
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = var.tgw_id

  timeouts {
    create = "5m"
  }
}

resource "aws_ec2_transit_gateway_connect_peer" "tgw_gre_peer" {
  count                         = local.connection_type == "gre" ? (local.is_ha ? 4 : 2) : 0
  peer_address                  = count.index < 2 ? var.gw_object.private_ip : var.gw_object.ha_private_ip
  inside_cidr_blocks            = [local.tunnel_cidrs[count.index]]
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.attachment[0].id
  bgp_asn                       = var.aviatrix_asn
  tags = {
    "Name" = format("%s-peer-%s", var.gw_object.gw_name, count.index + 1)
  }
}

resource "aviatrix_transit_external_device_conn" "non_ha" {
  count                         = local.connection_type == "gre" && !local.is_ha ? 1 : 0
  vpc_id                        = var.vpc_object.vpc_id
  connection_name               = format("%s-gre-a", var.gw_object.gw_name)
  gw_name                       = var.gw_object.gw_name
  connection_type               = "bgp"
  tunnel_protocol               = "GRE"
  bgp_local_as_num              = var.gw_object.local_as_number
  bgp_remote_as_num             = var.tgw_asn
  enable_learned_cidrs_approval = var.enable_learned_cidrs_approval
  approved_cidrs                = var.approved_cidrs
  remote_gateway_ip = format("%s,%s",
    aws_ec2_transit_gateway_connect_peer.tgw_gre_peer[0].transit_gateway_address,
    aws_ec2_transit_gateway_connect_peer.tgw_gre_peer[1].transit_gateway_address,
  )

  direct_connect = true
  ha_enabled     = false
  local_tunnel_cidr = (local.is_ha ?
    format("%s/29,%s/29",
      cidrhost(local.tunnel_cidrs[0], 1),
      cidrhost(local.tunnel_cidrs[1], 1),
    )
    :
    format("%s/29", cidrhost(local.tunnel_cidrs[0], 0))
  )

  remote_tunnel_cidr = (local.is_ha ?
    format("%s/29,%s/29",
      cidrhost(local.tunnel_cidrs[0], 2),
      cidrhost(local.tunnel_cidrs[1], 2),
    )
    :
    format("%s/29", cidrhost(local.tunnel_cidrs[0], 1))
  )
}

resource "aviatrix_transit_external_device_conn" "to_tgw_a" {
  count                         = local.connection_type == "gre" && local.is_ha ? 1 : 0
  vpc_id                        = var.vpc_object.vpc_id
  connection_name               = format("%s-gre-a", var.gw_object.gw_name)
  gw_name                       = var.gw_object.gw_name
  connection_type               = "bgp"
  tunnel_protocol               = "GRE"
  bgp_local_as_num              = var.gw_object.local_as_number
  bgp_remote_as_num             = var.tgw_asn
  enable_learned_cidrs_approval = var.enable_learned_cidrs_approval
  approved_cidrs                = var.approved_cidrs
  remote_gateway_ip = format("%s,%s",
    aws_ec2_transit_gateway_connect_peer.tgw_gre_peer[0].transit_gateway_address,
    aws_ec2_transit_gateway_connect_peer.tgw_gre_peer[2].transit_gateway_address,
  )

  direct_connect = true
  ha_enabled     = false
  local_tunnel_cidr = format("%s/29,%s/29",
    cidrhost(local.tunnel_cidrs[0], 1),
    cidrhost(local.tunnel_cidrs[2], 1),
  )

  remote_tunnel_cidr = format("%s/29,%s/29",
    cidrhost(local.tunnel_cidrs[0], 2),
    cidrhost(local.tunnel_cidrs[2], 2),
  )
}

resource "aviatrix_transit_external_device_conn" "to_tgw_b" {
  count                         = local.connection_type == "gre" && local.is_ha ? 1 : 0
  vpc_id                        = var.vpc_object.vpc_id
  connection_name               = format("%s-gre-b", var.gw_object.gw_name)
  gw_name                       = var.gw_object.gw_name
  connection_type               = "bgp"
  tunnel_protocol               = "GRE"
  bgp_local_as_num              = var.gw_object.local_as_number
  bgp_remote_as_num             = var.tgw_asn
  enable_learned_cidrs_approval = var.enable_learned_cidrs_approval
  approved_cidrs                = var.approved_cidrs
  remote_gateway_ip = format("%s,%s",
    aws_ec2_transit_gateway_connect_peer.tgw_gre_peer[1].transit_gateway_address,
    aws_ec2_transit_gateway_connect_peer.tgw_gre_peer[3].transit_gateway_address,
  )

  direct_connect = true
  ha_enabled     = false
  local_tunnel_cidr = format("%s/29,%s/29",
    cidrhost(local.tunnel_cidrs[1], 1),
    cidrhost(local.tunnel_cidrs[3], 1),
  )

  remote_tunnel_cidr = format("%s/29,%s/29",
    cidrhost(local.tunnel_cidrs[1], 2),
    cidrhost(local.tunnel_cidrs[3], 2),
  )
}
