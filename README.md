# CATO IPSec Alibaba Terraform module

Terraform module which creates an IPsec site in the Cato Management Application (CMA), and a primary and secondary IPsec tunnel from Alibaba Cloud to the Cato platform.

## NOTE
- This module looks up the Cato Site Location based on the Alibaba region specified. To override, pass the `site_location` object. For exact city/state/country/timezone syntax see the [cato_siteLocation data source](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/siteLocation).
- For help finding a license id to assign, see the [cato_licensingInfo data source](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/licensingInfo).
- HA is always built: one public dual-zone VPN gateway (two public IPs) carrying one dual-tunnel `alicloud_vpn_connection` (roles `master`/`slave`).
- `cn-guangzhou` and other China-mainland regions require a **China-site (aliyun.com)** account and its AccessKey — International-site keys cannot see China-mainland regions.

## Usage

```hcl
terraform {
  required_providers {
    cato     = { source = "catonetworks/cato", version = ">= 0.0.69" }
    alicloud = { source = "aliyun/alicloud", version = ">= 1.293.0, < 2.0.0" }
  }
}

variable "baseurl" {}
variable "token" {}
variable "account_id" {}

provider "alicloud" {
  region = "cn-guangzhou" # or rely on ALICLOUD_REGION
  # access_key / secret_key via ALICLOUD_ACCESS_KEY / ALICLOUD_SECRET_KEY
}

provider "cato" {
  baseurl    = var.baseurl
  token      = var.token
  account_id = var.account_id
}

# Example — Build with BGP (recommended)
module "ipsec-alibaba-bgp" {
  source     = "catonetworks/ipsec-alibaba/cato"
  token      = var.token
  account_id = var.account_id

  alicloud_region         = "cn-guangzhou"
  build_alicloud_vpc      = true
  alicloud_vpc_cidr       = "10.20.0.0/16"
  alicloud_vswitch_zone_a = "cn-guangzhou-a"
  alicloud_vswitch_zone_b = "cn-guangzhou-b"
  alicloud_vswitch_a_cidr = "10.20.1.0/24"
  alicloud_vswitch_b_cidr = "10.20.2.0/24"

  site_name            = "My-Alibaba-Cato-IPSec-Site"
  site_description     = "Alibaba Cato IPSec Site (Guangzhou) with BGP"
  native_network_range = "10.20.0.0/16"

  # Cato PoP public IPs (allocated in the CMA)
  primary_cato_pop_ip   = "x.x.x.x"
  secondary_cato_pop_ip = "y.y.y.y"

  # BGP: Alibaba per-tunnel APIPA (within 169.254.0.0/16, /30) + Cato APIPA peering IPs
  alicloud_enable_bgp    = true
  alicloud_bgp_asn       = 45104
  cato_bgp_asn           = 65001
  primary_tunnel_cidr    = "169.254.30.0/30"
  primary_local_bgp_ip   = "169.254.30.1"
  secondary_tunnel_cidr  = "169.254.40.0/30"
  secondary_local_bgp_ip = "169.254.40.1"
  primary_private_cato_ip   = "169.254.30.2"
  primary_private_site_ip   = "169.254.30.1"
  secondary_private_cato_ip = "169.254.40.2"
  secondary_private_site_ip = "169.254.40.1"

  downstream_bw = 100
  upstream_bw   = 100

  tags = {
    builtwith = "terraform"
    repo      = "https://github.com/catonetworks/terraform-cato-ipsec-alibaba"
  }
}

# Example — without BGP (static / policy-based; set the remote encryption domain)
module "ipsec-alibaba-nobgp" {
  source     = "catonetworks/ipsec-alibaba/cato"
  token      = var.token
  account_id = var.account_id

  alicloud_region         = "cn-guangzhou"
  build_alicloud_vpc      = true
  alicloud_vpc_cidr       = "10.21.0.0/16"
  alicloud_vswitch_zone_a = "cn-guangzhou-a"
  alicloud_vswitch_zone_b = "cn-guangzhou-b"
  alicloud_vswitch_a_cidr = "10.21.1.0/24"
  alicloud_vswitch_b_cidr = "10.21.2.0/24"

  site_name            = "My-Alibaba-Cato-IPSec-Site-nobgp"
  site_description     = "Alibaba Cato IPSec Site (Guangzhou), static routing"
  native_network_range = "10.21.0.0/16"

  primary_cato_pop_ip   = "x.x.x.x"
  secondary_cato_pop_ip = "y.y.y.y"

  alicloud_enable_bgp = false
  cato_local_networks = ["10.41.0.0/16", "10.254.254.0/24"]

  downstream_bw = 100
  upstream_bw   = 100
}
```

## Allocated IP Reference

Use the catocli to list the allocated Cato PoP IPs for your account:

```bash
catocli entity allocatedIP list
```

## Site Location Reference

```bash
catocli query siteLocation '{"filters":[{"search":"Guangzhou","field":"city","operation":"exact"}]}'
```

## Authors

Maintained by [Cato Networks](https://github.com/catonetworks).

## License

Apache 2.0. See [LICENSE](./LICENSE).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_alicloud"></a> [alicloud](#requirement\_alicloud) | >= 1.293.0, < 2.0.0 |
| <a name="requirement_cato"></a> [cato](#requirement\_cato) | >= 0.0.69 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_alicloud"></a> [alicloud](#provider\_alicloud) | 1.293.0 |
| <a name="provider_cato"></a> [cato](#provider\_cato) | 1.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [alicloud_vpc.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vpc) | resource |
| [alicloud_vpn_connection.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vpn_connection) | resource |
| [alicloud_vpn_customer_gateway.primary](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vpn_customer_gateway) | resource |
| [alicloud_vpn_customer_gateway.secondary](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vpn_customer_gateway) | resource |
| [alicloud_vpn_gateway.this](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vpn_gateway) | resource |
| [alicloud_vswitch.zone_a](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vswitch) | resource |
| [alicloud_vswitch.zone_b](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vswitch) | resource |
| [cato_bgp_peer.backup](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/bgp_peer) | resource |
| [cato_bgp_peer.primary](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/bgp_peer) | resource |
| [cato_ipsec_site.ipsec-site](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/ipsec_site) | resource |
| [cato_license.license](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/license) | resource |
| [random_password.shared_key_primary](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.shared_key_secondary](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.update_ipsec_site_details-bgp](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.update_ipsec_site_details-nobgp](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [cato_allocatedIp.primary](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/allocatedIp) | data source |
| [cato_allocatedIp.secondary](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/allocatedIp) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cato account ID. | `number` | n/a | yes |
| <a name="input_alicloud_auto_propagate"></a> [alicloud\_auto\_propagate](#input\_alicloud\_auto\_propagate) | Auto-propagate BGP-learned routes into the VPC route table. | `bool` | `true` | no |
| <a name="input_alicloud_bgp_asn"></a> [alicloud\_bgp\_asn](#input\_alicloud\_bgp\_asn) | Alibaba-side (peer) BGP ASN. | `number` | `45104` | no |
| <a name="input_alicloud_enable_bgp"></a> [alicloud\_enable\_bgp](#input\_alicloud\_enable\_bgp) | Enable BGP over both tunnels. | `bool` | `true` | no |
| <a name="input_alicloud_enable_dpd"></a> [alicloud\_enable\_dpd](#input\_alicloud\_enable\_dpd) | n/a | `bool` | `true` | no |
| <a name="input_alicloud_enable_nat_traversal"></a> [alicloud\_enable\_nat\_traversal](#input\_alicloud\_enable\_nat\_traversal) | n/a | `bool` | `true` | no |
| <a name="input_alicloud_gateway_bandwidth"></a> [alicloud\_gateway\_bandwidth](#input\_alicloud\_gateway\_bandwidth) | VPN gateway bandwidth in Mbps (public gw valid: 5,10,20,50,100,200,500,1000). | `number` | `100` | no |
| <a name="input_alicloud_ike_auth_alg"></a> [alicloud\_ike\_auth\_alg](#input\_alicloud\_ike\_auth\_alg) | n/a | `string` | `"sha256"` | no |
| <a name="input_alicloud_ike_enc_alg"></a> [alicloud\_ike\_enc\_alg](#input\_alicloud\_ike\_enc\_alg) | n/a | `string` | `"aes256"` | no |
| <a name="input_alicloud_ike_lifetime"></a> [alicloud\_ike\_lifetime](#input\_alicloud\_ike\_lifetime) | n/a | `number` | `28800` | no |
| <a name="input_alicloud_ike_mode"></a> [alicloud\_ike\_mode](#input\_alicloud\_ike\_mode) | n/a | `string` | `"main"` | no |
| <a name="input_alicloud_ike_pfs"></a> [alicloud\_ike\_pfs](#input\_alicloud\_ike\_pfs) | n/a | `string` | `"group14"` | no |
| <a name="input_alicloud_ike_version"></a> [alicloud\_ike\_version](#input\_alicloud\_ike\_version) | ───────────────────────────────────────────────────────────────────────────── Alibaba per-tunnel IKE / IPsec policy ───────────────────────────────────────────────────────────────────────────── | `string` | `"ikev2"` | no |
| <a name="input_alicloud_ipsec_auth_alg"></a> [alicloud\_ipsec\_auth\_alg](#input\_alicloud\_ipsec\_auth\_alg) | n/a | `string` | `"sha256"` | no |
| <a name="input_alicloud_ipsec_enc_alg"></a> [alicloud\_ipsec\_enc\_alg](#input\_alicloud\_ipsec\_enc\_alg) | n/a | `string` | `"aes256"` | no |
| <a name="input_alicloud_ipsec_lifetime"></a> [alicloud\_ipsec\_lifetime](#input\_alicloud\_ipsec\_lifetime) | n/a | `number` | `28800` | no |
| <a name="input_alicloud_ipsec_pfs"></a> [alicloud\_ipsec\_pfs](#input\_alicloud\_ipsec\_pfs) | n/a | `string` | `"group14"` | no |
| <a name="input_alicloud_payment_type"></a> [alicloud\_payment\_type](#input\_alicloud\_payment\_type) | VPN gateway payment type: PayAsYouGo or Subscription. | `string` | `"PayAsYouGo"` | no |
| <a name="input_alicloud_region"></a> [alicloud\_region](#input\_alicloud\_region) | Alibaba Cloud region, e.g. cn-guangzhou. | `string` | n/a | yes |
| <a name="input_alicloud_vpc_cidr"></a> [alicloud\_vpc\_cidr](#input\_alicloud\_vpc\_cidr) | VPC CIDR (when build\_alicloud\_vpc = true). | `string` | `null` | no |
| <a name="input_alicloud_vpc_id"></a> [alicloud\_vpc\_id](#input\_alicloud\_vpc\_id) | Existing VPC ID (when build\_alicloud\_vpc = false). | `string` | `null` | no |
| <a name="input_alicloud_vpc_name"></a> [alicloud\_vpc\_name](#input\_alicloud\_vpc\_name) | VPC name (when build\_alicloud\_vpc = true). Defaults to <site\_name>-vpc. | `string` | `null` | no |
| <a name="input_alicloud_vswitch_a_cidr"></a> [alicloud\_vswitch\_a\_cidr](#input\_alicloud\_vswitch\_a\_cidr) | Primary gateway vSwitch CIDR (when build\_alicloud\_vpc = true). | `string` | `null` | no |
| <a name="input_alicloud_vswitch_a_id"></a> [alicloud\_vswitch\_a\_id](#input\_alicloud\_vswitch\_a\_id) | Existing primary gateway vSwitch ID (when build\_alicloud\_vpc = false). | `string` | `null` | no |
| <a name="input_alicloud_vswitch_b_cidr"></a> [alicloud\_vswitch\_b\_cidr](#input\_alicloud\_vswitch\_b\_cidr) | Secondary gateway vSwitch CIDR (when build\_alicloud\_vpc = true). | `string` | `null` | no |
| <a name="input_alicloud_vswitch_b_id"></a> [alicloud\_vswitch\_b\_id](#input\_alicloud\_vswitch\_b\_id) | Existing secondary gateway vSwitch ID (when build\_alicloud\_vpc = false). | `string` | `null` | no |
| <a name="input_alicloud_vswitch_zone_a"></a> [alicloud\_vswitch\_zone\_a](#input\_alicloud\_vswitch\_zone\_a) | Zone for the primary gateway vSwitch, e.g. cn-guangzhou-a. | `string` | `null` | no |
| <a name="input_alicloud_vswitch_zone_b"></a> [alicloud\_vswitch\_zone\_b](#input\_alicloud\_vswitch\_zone\_b) | Zone for the secondary (DR) gateway vSwitch, e.g. cn-guangzhou-b. | `string` | `null` | no |
| <a name="input_baseurl"></a> [baseurl](#input\_baseurl) | Cato API base URL. | `string` | `"https://api.catonetworks.com/api/v1/graphql2"` | no |
| <a name="input_build_alicloud_vpc"></a> [build\_alicloud\_vpc](#input\_build\_alicloud\_vpc) | Whether this module creates the VPC + two gateway vSwitches. Set false to reference existing ones by ID. | `bool` | `true` | no |
| <a name="input_cato_authMessage_cipher"></a> [cato\_authMessage\_cipher](#input\_cato\_authMessage\_cipher) | n/a | `string` | `"AUTOMATIC"` | no |
| <a name="input_cato_authMessage_dhGroup"></a> [cato\_authMessage\_dhGroup](#input\_cato\_authMessage\_dhGroup) | n/a | `string` | `"AUTOMATIC"` | no |
| <a name="input_cato_authMessage_integrity"></a> [cato\_authMessage\_integrity](#input\_cato\_authMessage\_integrity) | n/a | `string` | `"AUTOMATIC"` | no |
| <a name="input_cato_bgp_asn"></a> [cato\_bgp\_asn](#input\_cato\_bgp\_asn) | Cato-side BGP ASN. | `number` | `65001` | no |
| <a name="input_cato_connectionMode"></a> [cato\_connectionMode](#input\_cato\_connectionMode) | n/a | `string` | `"BIDIRECTIONAL"` | no |
| <a name="input_cato_identificationType"></a> [cato\_identificationType](#input\_cato\_identificationType) | n/a | `string` | `"IPV4"` | no |
| <a name="input_cato_initMessage_cipher"></a> [cato\_initMessage\_cipher](#input\_cato\_initMessage\_cipher) | n/a | `string` | `"AUTOMATIC"` | no |
| <a name="input_cato_initMessage_dhGroup"></a> [cato\_initMessage\_dhGroup](#input\_cato\_initMessage\_dhGroup) | ───────────────────────────────────────────────────────────────────────────── Cato IKEv2 message tuning (applied post-create via the API PATCH) ───────────────────────────────────────────────────────────────────────────── | `string` | `"AUTOMATIC"` | no |
| <a name="input_cato_initMessage_integrity"></a> [cato\_initMessage\_integrity](#input\_cato\_initMessage\_integrity) | n/a | `string` | `"AUTOMATIC"` | no |
| <a name="input_cato_initMessage_prf"></a> [cato\_initMessage\_prf](#input\_cato\_initMessage\_prf) | n/a | `string` | `"AUTOMATIC"` | no |
| <a name="input_cato_local_networks"></a> [cato\_local\_networks](#input\_cato\_local\_networks) | CIDRs behind Cato (used as the remote encryption domain when BGP is disabled). | `list(string)` | <pre>[<br/>  "10.41.0.0/16",<br/>  "10.254.254.0/24"<br/>]</pre> | no |
| <a name="input_cato_primary_bgp_advertise_all"></a> [cato\_primary\_bgp\_advertise\_all](#input\_cato\_primary\_bgp\_advertise\_all) | n/a | `bool` | `true` | no |
| <a name="input_cato_primary_bgp_advertise_default_route"></a> [cato\_primary\_bgp\_advertise\_default\_route](#input\_cato\_primary\_bgp\_advertise\_default\_route) | n/a | `bool` | `false` | no |
| <a name="input_cato_primary_bgp_advertise_summary_route"></a> [cato\_primary\_bgp\_advertise\_summary\_route](#input\_cato\_primary\_bgp\_advertise\_summary\_route) | n/a | `bool` | `false` | no |
| <a name="input_cato_primary_bgp_bfd_multiplier"></a> [cato\_primary\_bgp\_bfd\_multiplier](#input\_cato\_primary\_bgp\_bfd\_multiplier) | n/a | `number` | `5` | no |
| <a name="input_cato_primary_bgp_bfd_receive_interval"></a> [cato\_primary\_bgp\_bfd\_receive\_interval](#input\_cato\_primary\_bgp\_bfd\_receive\_interval) | n/a | `number` | `1000` | no |
| <a name="input_cato_primary_bgp_bfd_transmit_interval"></a> [cato\_primary\_bgp\_bfd\_transmit\_interval](#input\_cato\_primary\_bgp\_bfd\_transmit\_interval) | n/a | `number` | `1000` | no |
| <a name="input_cato_primary_bgp_default_action"></a> [cato\_primary\_bgp\_default\_action](#input\_cato\_primary\_bgp\_default\_action) | n/a | `string` | `"ACCEPT"` | no |
| <a name="input_cato_primary_bgp_metric"></a> [cato\_primary\_bgp\_metric](#input\_cato\_primary\_bgp\_metric) | cato\_bgp\_peer tuning | `number` | `100` | no |
| <a name="input_cato_primary_bgp_peer_name"></a> [cato\_primary\_bgp\_peer\_name](#input\_cato\_primary\_bgp\_peer\_name) | n/a | `string` | `null` | no |
| <a name="input_cato_secondary_bgp_advertise_all"></a> [cato\_secondary\_bgp\_advertise\_all](#input\_cato\_secondary\_bgp\_advertise\_all) | n/a | `bool` | `true` | no |
| <a name="input_cato_secondary_bgp_advertise_default_route"></a> [cato\_secondary\_bgp\_advertise\_default\_route](#input\_cato\_secondary\_bgp\_advertise\_default\_route) | n/a | `bool` | `false` | no |
| <a name="input_cato_secondary_bgp_advertise_summary_route"></a> [cato\_secondary\_bgp\_advertise\_summary\_route](#input\_cato\_secondary\_bgp\_advertise\_summary\_route) | n/a | `bool` | `false` | no |
| <a name="input_cato_secondary_bgp_bfd_multiplier"></a> [cato\_secondary\_bgp\_bfd\_multiplier](#input\_cato\_secondary\_bgp\_bfd\_multiplier) | n/a | `number` | `5` | no |
| <a name="input_cato_secondary_bgp_bfd_receive_interval"></a> [cato\_secondary\_bgp\_bfd\_receive\_interval](#input\_cato\_secondary\_bgp\_bfd\_receive\_interval) | n/a | `number` | `1000` | no |
| <a name="input_cato_secondary_bgp_bfd_transmit_interval"></a> [cato\_secondary\_bgp\_bfd\_transmit\_interval](#input\_cato\_secondary\_bgp\_bfd\_transmit\_interval) | n/a | `number` | `1000` | no |
| <a name="input_cato_secondary_bgp_default_action"></a> [cato\_secondary\_bgp\_default\_action](#input\_cato\_secondary\_bgp\_default\_action) | n/a | `string` | `"ACCEPT"` | no |
| <a name="input_cato_secondary_bgp_metric"></a> [cato\_secondary\_bgp\_metric](#input\_cato\_secondary\_bgp\_metric) | n/a | `number` | `200` | no |
| <a name="input_cato_secondary_bgp_peer_name"></a> [cato\_secondary\_bgp\_peer\_name](#input\_cato\_secondary\_bgp\_peer\_name) | n/a | `string` | `null` | no |
| <a name="input_downstream_bw"></a> [downstream\_bw](#input\_downstream\_bw) | n/a | `number` | n/a | yes |
| <a name="input_license_bw"></a> [license\_bw](#input\_license\_bw) | n/a | `string` | `null` | no |
| <a name="input_license_id"></a> [license\_id](#input\_license\_id) | n/a | `string` | `null` | no |
| <a name="input_native_network_range"></a> [native\_network\_range](#input\_native\_network\_range) | n/a | `string` | n/a | yes |
| <a name="input_primary_cato_pop_ip"></a> [primary\_cato\_pop\_ip](#input\_primary\_cato\_pop\_ip) | Primary Cato PoP public IP (allocatedIP) for tunnel 1. | `string` | n/a | yes |
| <a name="input_primary_connection_shared_key"></a> [primary\_connection\_shared\_key](#input\_primary\_connection\_shared\_key) | PSK for tunnel 1. If null, a random key is generated and used on both sides. | `string` | `null` | no |
| <a name="input_primary_destination_type"></a> [primary\_destination\_type](#input\_primary\_destination\_type) | n/a | `string` | `null` | no |
| <a name="input_primary_local_bgp_ip"></a> [primary\_local\_bgp\_ip](#input\_primary\_local\_bgp\_ip) | Alibaba BGP IP inside primary\_tunnel\_cidr. | `string` | `"169.254.30.1"` | no |
| <a name="input_primary_pop_location_id"></a> [primary\_pop\_location\_id](#input\_primary\_pop\_location\_id) | n/a | `string` | `null` | no |
| <a name="input_primary_private_cato_ip"></a> [primary\_private\_cato\_ip](#input\_primary\_private\_cato\_ip) | Cato APIPA peering (private) IPs — used on the Cato side (cato\_ipsec\_site tunnels + cato\_bgp\_peer). | `string` | `null` | no |
| <a name="input_primary_private_site_ip"></a> [primary\_private\_site\_ip](#input\_primary\_private\_site\_ip) | n/a | `string` | `null` | no |
| <a name="input_primary_tunnel_cidr"></a> [primary\_tunnel\_cidr](#input\_primary\_tunnel\_cidr) | APIPA /30 within 169.254.0.0/16 for the primary tunnel BGP session. | `string` | `"169.254.30.0/30"` | no |
| <a name="input_secondary_cato_pop_ip"></a> [secondary\_cato\_pop\_ip](#input\_secondary\_cato\_pop\_ip) | Secondary Cato PoP public IP (allocatedIP) for tunnel 2. | `string` | n/a | yes |
| <a name="input_secondary_connection_shared_key"></a> [secondary\_connection\_shared\_key](#input\_secondary\_connection\_shared\_key) | PSK for tunnel 2. If null, a random key is generated and used on both sides. | `string` | `null` | no |
| <a name="input_secondary_destination_type"></a> [secondary\_destination\_type](#input\_secondary\_destination\_type) | n/a | `string` | `null` | no |
| <a name="input_secondary_local_bgp_ip"></a> [secondary\_local\_bgp\_ip](#input\_secondary\_local\_bgp\_ip) | Alibaba BGP IP inside secondary\_tunnel\_cidr. | `string` | `"169.254.40.1"` | no |
| <a name="input_secondary_pop_location_id"></a> [secondary\_pop\_location\_id](#input\_secondary\_pop\_location\_id) | n/a | `string` | `null` | no |
| <a name="input_secondary_private_cato_ip"></a> [secondary\_private\_cato\_ip](#input\_secondary\_private\_cato\_ip) | n/a | `string` | `null` | no |
| <a name="input_secondary_private_site_ip"></a> [secondary\_private\_site\_ip](#input\_secondary\_private\_site\_ip) | n/a | `string` | `null` | no |
| <a name="input_secondary_tunnel_cidr"></a> [secondary\_tunnel\_cidr](#input\_secondary\_tunnel\_cidr) | APIPA /30 within 169.254.0.0/16 for the secondary tunnel BGP session. | `string` | `"169.254.40.0/30"` | no |
| <a name="input_site_description"></a> [site\_description](#input\_site\_description) | n/a | `string` | n/a | yes |
| <a name="input_site_location"></a> [site\_location](#input\_site\_location) | n/a | <pre>object({<br/>    city         = optional(string)<br/>    country_code = optional(string)<br/>    state_code   = optional(string)<br/>    timezone     = optional(string)<br/>  })</pre> | <pre>{<br/>  "city": null,<br/>  "country_code": null,<br/>  "state_code": null,<br/>  "timezone": null<br/>}</pre> | no |
| <a name="input_site_name"></a> [site\_name](#input\_site\_name) | n/a | `string` | n/a | yes |
| <a name="input_site_type"></a> [site\_type](#input\_site\_type) | n/a | `string` | `"CLOUD_DC"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_token"></a> [token](#input\_token) | Cato API token. | `string` | n/a | yes |
| <a name="input_upstream_bw"></a> [upstream\_bw](#input\_upstream\_bw) | n/a | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cato_site_id"></a> [cato\_site\_id](#output\_cato\_site\_id) | Cato IPsec site ID. |
| <a name="output_customer_gateway_primary_id"></a> [customer\_gateway\_primary\_id](#output\_customer\_gateway\_primary\_id) | Primary customer gateway ID (Cato primary PoP). |
| <a name="output_customer_gateway_secondary_id"></a> [customer\_gateway\_secondary\_id](#output\_customer\_gateway\_secondary\_id) | Secondary customer gateway ID (Cato secondary PoP). |
| <a name="output_primary_connection_shared_key"></a> [primary\_connection\_shared\_key](#output\_primary\_connection\_shared\_key) | PSK used for tunnel 1 (provided or generated). |
| <a name="output_secondary_connection_shared_key"></a> [secondary\_connection\_shared\_key](#output\_secondary\_connection\_shared\_key) | PSK used for tunnel 2 (provided or generated). |
| <a name="output_site_location"></a> [site\_location](#output\_site\_location) | Resolved Cato site location. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID (created or referenced). |
| <a name="output_vpn_connection_id"></a> [vpn\_connection\_id](#output\_vpn\_connection\_id) | Alibaba dual-tunnel VPN connection ID. |
| <a name="output_vpn_gateway_id"></a> [vpn\_gateway\_id](#output\_vpn\_gateway\_id) | Alibaba VPN gateway ID. |
| <a name="output_vpn_gateway_primary_public_ip"></a> [vpn\_gateway\_primary\_public\_ip](#output\_vpn\_gateway\_primary\_public\_ip) | Primary (internet\_ip) public IP of the Alibaba VPN gateway. |
| <a name="output_vpn_gateway_secondary_public_ip"></a> [vpn\_gateway\_secondary\_public\_ip](#output\_vpn\_gateway\_secondary\_public\_ip) | Secondary (disaster\_recovery\_internet\_ip) public IP of the Alibaba VPN gateway. |
<!-- END_TF_DOCS -->
