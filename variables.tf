# ─────────────────────────────────────────────────────────────────────────────
# Cato provider
# ─────────────────────────────────────────────────────────────────────────────
variable "baseurl" {
  description = "Cato API base URL."
  type        = string
  default     = "https://api.catonetworks.com/api/v1/graphql2"
}

variable "token" {
  description = "Cato API token."
  type        = string
}

variable "account_id" {
  description = "Cato account ID."
  type        = number
}

# ─────────────────────────────────────────────────────────────────────────────
# Alibaba Cloud — network build-or-reference
# ─────────────────────────────────────────────────────────────────────────────
variable "alicloud_region" {
  description = "Alibaba Cloud region, e.g. cn-guangzhou."
  type        = string
}

variable "build_alicloud_vpc" {
  description = "Whether this module creates the VPC + two gateway vSwitches. Set false to reference existing ones by ID."
  type        = bool
  default     = true
}

variable "alicloud_vpc_id" {
  description = "Existing VPC ID (when build_alicloud_vpc = false)."
  type        = string
  default     = null
}

variable "alicloud_vpc_cidr" {
  description = "VPC CIDR (when build_alicloud_vpc = true)."
  type        = string
  default     = null
}

variable "alicloud_vpc_name" {
  description = "VPC name (when build_alicloud_vpc = true). Defaults to <site_name>-vpc."
  type        = string
  default     = null
}

variable "alicloud_vswitch_zone_a" {
  description = "Zone for the primary gateway vSwitch, e.g. cn-guangzhou-a."
  type        = string
  default     = null
}

variable "alicloud_vswitch_zone_b" {
  description = "Zone for the secondary (DR) gateway vSwitch, e.g. cn-guangzhou-b."
  type        = string
  default     = null
}

variable "alicloud_vswitch_a_cidr" {
  description = "Primary gateway vSwitch CIDR (when build_alicloud_vpc = true)."
  type        = string
  default     = null
}

variable "alicloud_vswitch_b_cidr" {
  description = "Secondary gateway vSwitch CIDR (when build_alicloud_vpc = true)."
  type        = string
  default     = null
}

variable "alicloud_vswitch_a_id" {
  description = "Existing primary gateway vSwitch ID (when build_alicloud_vpc = false)."
  type        = string
  default     = null
}

variable "alicloud_vswitch_b_id" {
  description = "Existing secondary gateway vSwitch ID (when build_alicloud_vpc = false)."
  type        = string
  default     = null
}

variable "alicloud_gateway_bandwidth" {
  description = "VPN gateway bandwidth in Mbps (public gw valid: 5,10,20,50,100,200,500,1000)."
  type        = number
  default     = 100
}

variable "alicloud_payment_type" {
  description = "VPN gateway payment type: PayAsYouGo or Subscription."
  type        = string
  default     = "PayAsYouGo"
}

variable "alicloud_auto_propagate" {
  description = "Auto-propagate BGP-learned routes into the VPC route table."
  type        = bool
  default     = true
}

# ─────────────────────────────────────────────────────────────────────────────
# Alibaba per-tunnel IKE / IPsec policy
# ─────────────────────────────────────────────────────────────────────────────
variable "alicloud_ike_version" {
  type    = string
  default = "ikev2"
}
variable "alicloud_ike_mode" {
  type    = string
  default = "main"
}
variable "alicloud_ike_enc_alg" {
  type    = string
  default = "aes256"
}
variable "alicloud_ike_auth_alg" {
  type    = string
  default = "sha256"
}
variable "alicloud_ike_pfs" {
  type    = string
  default = "group14"
}
variable "alicloud_ike_lifetime" {
  type    = number
  default = 28800
}
variable "alicloud_ipsec_enc_alg" {
  type    = string
  default = "aes256"
}
variable "alicloud_ipsec_auth_alg" {
  type    = string
  default = "sha256"
}
variable "alicloud_ipsec_pfs" {
  type    = string
  default = "group14"
}
variable "alicloud_ipsec_lifetime" {
  type    = number
  default = 28800
}
variable "alicloud_enable_dpd" {
  type    = bool
  default = true
}
variable "alicloud_enable_nat_traversal" {
  type    = bool
  default = true
}

# ─────────────────────────────────────────────────────────────────────────────
# BGP
# ─────────────────────────────────────────────────────────────────────────────
variable "alicloud_enable_bgp" {
  description = "Enable BGP over both tunnels."
  type        = bool
  default     = true
}

variable "alicloud_bgp_asn" {
  description = "Alibaba-side (peer) BGP ASN."
  type        = number
  default     = 45104
}

variable "cato_bgp_asn" {
  description = "Cato-side BGP ASN."
  type        = number
  default     = 65001
}

variable "primary_tunnel_cidr" {
  description = "APIPA /30 within 169.254.0.0/16 for the primary tunnel BGP session."
  type        = string
  default     = "169.254.30.0/30"
}
variable "primary_local_bgp_ip" {
  description = "Alibaba BGP IP inside primary_tunnel_cidr."
  type        = string
  default     = "169.254.30.1"
}
variable "secondary_tunnel_cidr" {
  description = "APIPA /30 within 169.254.0.0/16 for the secondary tunnel BGP session."
  type        = string
  default     = "169.254.40.0/30"
}
variable "secondary_local_bgp_ip" {
  description = "Alibaba BGP IP inside secondary_tunnel_cidr."
  type        = string
  default     = "169.254.40.1"
}

# Cato APIPA peering (private) IPs — used on the Cato side (cato_ipsec_site tunnels + cato_bgp_peer).
variable "primary_private_cato_ip" {
  type    = string
  default = null
}
variable "primary_private_site_ip" {
  type    = string
  default = null
}
variable "secondary_private_cato_ip" {
  type    = string
  default = null
}
variable "secondary_private_site_ip" {
  type    = string
  default = null
}

# cato_bgp_peer tuning
variable "cato_primary_bgp_metric" {
  type    = number
  default = 100
}
variable "cato_secondary_bgp_metric" {
  type    = number
  default = 200
}
variable "cato_primary_bgp_peer_name" {
  type    = string
  default = null
}
variable "cato_secondary_bgp_peer_name" {
  type    = string
  default = null
}
variable "cato_primary_bgp_default_action" {
  type    = string
  default = "ACCEPT"
}
variable "cato_secondary_bgp_default_action" {
  type    = string
  default = "ACCEPT"
}
variable "cato_primary_bgp_advertise_all" {
  type    = bool
  default = true
}
variable "cato_secondary_bgp_advertise_all" {
  type    = bool
  default = true
}
variable "cato_primary_bgp_advertise_default_route" {
  type    = bool
  default = false
}
variable "cato_secondary_bgp_advertise_default_route" {
  type    = bool
  default = false
}
variable "cato_primary_bgp_advertise_summary_route" {
  type    = bool
  default = false
}
variable "cato_secondary_bgp_advertise_summary_route" {
  type    = bool
  default = false
}
variable "cato_primary_bgp_bfd_transmit_interval" {
  type    = number
  default = 1000
}
variable "cato_secondary_bgp_bfd_transmit_interval" {
  type    = number
  default = 1000
}
variable "cato_primary_bgp_bfd_receive_interval" {
  type    = number
  default = 1000
}
variable "cato_secondary_bgp_bfd_receive_interval" {
  type    = number
  default = 1000
}
variable "cato_primary_bgp_bfd_multiplier" {
  type    = number
  default = 5
}
variable "cato_secondary_bgp_bfd_multiplier" {
  type    = number
  default = 5
}

# ─────────────────────────────────────────────────────────────────────────────
# Cato site
# ─────────────────────────────────────────────────────────────────────────────
variable "primary_cato_pop_ip" {
  description = "Primary Cato PoP public IP (allocatedIP) for tunnel 1."
  type        = string
}

variable "secondary_cato_pop_ip" {
  description = "Secondary Cato PoP public IP (allocatedIP) for tunnel 2."
  type        = string
}

variable "site_name" {
  type = string
}

variable "site_description" {
  type = string
}

variable "native_network_range" {
  type = string
}

variable "site_type" {
  type    = string
  default = "CLOUD_DC"
  validation {
    condition     = contains(["DATACENTER", "BRANCH", "CLOUD_DC", "HEADQUARTERS"], var.site_type)
    error_message = "site_type must be one of DATACENTER, BRANCH, CLOUD_DC, HEADQUARTERS."
  }
}

variable "site_location" {
  type = object({
    city         = optional(string)
    country_code = optional(string)
    state_code   = optional(string)
    timezone     = optional(string)
  })
  default = { city = null, country_code = null, state_code = null, timezone = null }
}

variable "primary_destination_type" {
  type    = string
  default = null
}
variable "primary_pop_location_id" {
  type    = string
  default = null
}
variable "secondary_destination_type" {
  type    = string
  default = null
}
variable "secondary_pop_location_id" {
  type    = string
  default = null
}

variable "downstream_bw" {
  type = number
}
variable "upstream_bw" {
  type = number
}

variable "primary_connection_shared_key" {
  description = "PSK for tunnel 1. If null, a random key is generated and used on both sides."
  type        = string
  default     = null
}
variable "secondary_connection_shared_key" {
  description = "PSK for tunnel 2. If null, a random key is generated and used on both sides."
  type        = string
  default     = null
}

variable "license_id" {
  type    = string
  default = null
}
variable "license_bw" {
  type    = string
  default = null
}

variable "cato_local_networks" {
  description = "CIDRs behind Cato (used as the remote encryption domain when BGP is disabled)."
  type        = list(string)
  default     = ["10.41.0.0/16", "10.254.254.0/24"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Cato IKEv2 message tuning (applied post-create via the API PATCH)
# ─────────────────────────────────────────────────────────────────────────────
variable "cato_initMessage_dhGroup" {
  type    = string
  default = "AUTOMATIC"
}
variable "cato_initMessage_cipher" {
  type    = string
  default = "AUTOMATIC"
}
variable "cato_initMessage_integrity" {
  type    = string
  default = "AUTOMATIC"
}
variable "cato_initMessage_prf" {
  type    = string
  default = "AUTOMATIC"
}
variable "cato_authMessage_dhGroup" {
  type    = string
  default = "AUTOMATIC"
}
variable "cato_authMessage_cipher" {
  type    = string
  default = "AUTOMATIC"
}
variable "cato_authMessage_integrity" {
  type    = string
  default = "AUTOMATIC"
}
variable "cato_connectionMode" {
  type    = string
  default = "BIDIRECTIONAL"
}
variable "cato_identificationType" {
  type    = string
  default = "IPV4"
}

variable "tags" {
  type    = map(string)
  default = {}
}
