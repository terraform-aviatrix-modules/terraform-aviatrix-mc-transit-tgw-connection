# terraform-aviatrix-mc-transit-tgw-connection

### Description
This module creates an IPSEC connection between a single or HA Aviatrix transit gateway and an AWS TGW.

### Diagram
<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit-tgw-connection/blob/master/img/terraform-aviatrix-mc-transit-tgw-connection.png?raw=true" heigh="400">


### Compatibility
Module version | Terraform version | Controller version | Terraform provider version
:--- | :--- | :--- | :---
v1.0.0 | 0.13-1.0.1 | >=6.4 | >=0.2.19

### Usage Example
```
module "vpn1" {
  source  = "terraform-aviatrix-modules/mc-transit-tgw-connection/aviatrix"
  version = "1.0.0"

  gw_object    = data.aviatrix_transit_gateway.gw1
  aviatrix_asn = 65002
  tgw_asn      = data.aws_ec2_transit_gateway.tgw.amazon_side_asn
  tgw_id       = data.aws_ec2_transit_gateway.tgw.id
}
}
```

### Variables
The following variables are required:

key | value
:--- | :---
gw_object | The Aviatrix aransit gateway object with all attributes
aviatrix_asn | The ASN of the Aviatrix transit gateway
tgw_asn | The ASN configured on the TGW
tgw_id | The ID of the TGW

The following variables are optional:

key | default | value 
:---|:---|:---
tunnel_cidrs | ["169.254.101.0/30","169.254.102.0/30","169.254.103.0/30","169.254.104.0/30",] | A list of CIDR's to be used for the inner tunnel IP addresses
connection_name | ${var.gw_object.gw_name}_to_tgw | Name to use to create the S2C connections on the Aviatrix gateways

### Outputs
This module will return the following outputs:

key | description
:---|:---
