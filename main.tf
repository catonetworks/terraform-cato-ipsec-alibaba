# ─────────────────────────────────────────────────────────────────────────────
# Alibaba Cloud side — VPC / vSwitches / VPN gateway / customer gateways /
# dual-tunnel BGP IPsec connection.
# ─────────────────────────────────────────────────────────────────────────────

resource "alicloud_vpc" "this" {
  count      = var.build_alicloud_vpc ? 1 : 0
  vpc_name   = coalesce(var.alicloud_vpc_name, "${var.site_name}-vpc")
  cidr_block = var.alicloud_vpc_cidr
  tags       = var.tags
}

resource "alicloud_vswitch" "zone_a" {
  count        = var.build_alicloud_vpc ? 1 : 0
  vpc_id       = alicloud_vpc.this[0].id
  zone_id      = var.alicloud_vswitch_zone_a
  cidr_block   = var.alicloud_vswitch_a_cidr
  vswitch_name = "${var.site_name}-vsw-a"
  tags         = var.tags
}

resource "alicloud_vswitch" "zone_b" {
  count        = var.build_alicloud_vpc ? 1 : 0
  vpc_id       = alicloud_vpc.this[0].id
  zone_id      = var.alicloud_vswitch_zone_b
  cidr_block   = var.alicloud_vswitch_b_cidr
  vswitch_name = "${var.site_name}-vsw-b"
  tags         = var.tags
}

# Public, dual-zone HA gateway → two public IPs:
#   internet_ip (primary) / disaster_recovery_internet_ip (secondary).
resource "alicloud_vpn_gateway" "this" {
  vpn_gateway_name             = var.site_name
  vpc_id                       = local.vpc_id
  network_type                 = "public"
  vpn_type                     = "Normal"
  vswitch_id                   = local.vswitch_a_id
  disaster_recovery_vswitch_id = local.vswitch_b_id
  bandwidth                    = var.alicloud_gateway_bandwidth
  enable_ipsec                 = true
  enable_ssl                   = false
  payment_type                 = var.alicloud_payment_type
  auto_propagate               = var.alicloud_auto_propagate
  tags                         = var.tags
}

resource "alicloud_vpn_customer_gateway" "primary" {
  customer_gateway_name = "${var.site_name}-cato-primary"
  ip_address            = var.primary_cato_pop_ip
  asn                   = var.alicloud_enable_bgp ? var.cato_bgp_asn : null
  tags                  = var.tags
}

resource "alicloud_vpn_customer_gateway" "secondary" {
  customer_gateway_name = "${var.site_name}-cato-secondary"
  ip_address            = var.secondary_cato_pop_ip
  asn                   = var.alicloud_enable_bgp ? var.cato_bgp_asn : null
  tags                  = var.tags
}

resource "random_password" "shared_key_primary" {
  length  = 32
  special = false
}

resource "random_password" "shared_key_secondary" {
  length  = 32
  special = false
}

# One connection carries both tunnels (role master/slave) with per-tunnel BGP.
resource "alicloud_vpn_connection" "this" {
  vpn_gateway_id      = alicloud_vpn_gateway.this.id
  vpn_connection_name = var.site_name
  local_subnet        = [var.native_network_range]
  remote_subnet       = var.alicloud_enable_bgp ? ["0.0.0.0/0"] : var.cato_local_networks
  network_type        = "public"
  enable_tunnels_bgp  = var.alicloud_enable_bgp

  tunnel_options_specification {
    role                 = "master"
    customer_gateway_id  = alicloud_vpn_customer_gateway.primary.id
    enable_dpd           = var.alicloud_enable_dpd
    enable_nat_traversal = var.alicloud_enable_nat_traversal

    dynamic "tunnel_bgp_config" {
      for_each = var.alicloud_enable_bgp ? [1] : []
      content {
        local_asn    = var.alicloud_bgp_asn
        tunnel_cidr  = var.primary_tunnel_cidr
        local_bgp_ip = var.primary_local_bgp_ip
      }
    }

    tunnel_ike_config {
      ike_version  = var.alicloud_ike_version
      ike_mode     = var.alicloud_ike_mode
      ike_enc_alg  = var.alicloud_ike_enc_alg
      ike_auth_alg = var.alicloud_ike_auth_alg
      ike_pfs      = var.alicloud_ike_pfs
      ike_lifetime = var.alicloud_ike_lifetime
      psk          = var.primary_connection_shared_key == null ? random_password.shared_key_primary.result : var.primary_connection_shared_key
      local_id     = alicloud_vpn_gateway.this.internet_ip
      remote_id    = var.primary_cato_pop_ip
    }

    tunnel_ipsec_config {
      ipsec_enc_alg  = var.alicloud_ipsec_enc_alg
      ipsec_auth_alg = var.alicloud_ipsec_auth_alg
      ipsec_pfs      = var.alicloud_ipsec_pfs
      ipsec_lifetime = var.alicloud_ipsec_lifetime
    }
  }

  tunnel_options_specification {
    role                 = "slave"
    customer_gateway_id  = alicloud_vpn_customer_gateway.secondary.id
    enable_dpd           = var.alicloud_enable_dpd
    enable_nat_traversal = var.alicloud_enable_nat_traversal

    dynamic "tunnel_bgp_config" {
      for_each = var.alicloud_enable_bgp ? [1] : []
      content {
        local_asn    = var.alicloud_bgp_asn
        tunnel_cidr  = var.secondary_tunnel_cidr
        local_bgp_ip = var.secondary_local_bgp_ip
      }
    }

    tunnel_ike_config {
      ike_version  = var.alicloud_ike_version
      ike_mode     = var.alicloud_ike_mode
      ike_enc_alg  = var.alicloud_ike_enc_alg
      ike_auth_alg = var.alicloud_ike_auth_alg
      ike_pfs      = var.alicloud_ike_pfs
      ike_lifetime = var.alicloud_ike_lifetime
      psk          = var.secondary_connection_shared_key == null ? random_password.shared_key_secondary.result : var.secondary_connection_shared_key
      local_id     = alicloud_vpn_gateway.this.disaster_recovery_internet_ip
      remote_id    = var.secondary_cato_pop_ip
    }

    tunnel_ipsec_config {
      ipsec_enc_alg  = var.alicloud_ipsec_enc_alg
      ipsec_auth_alg = var.alicloud_ipsec_auth_alg
      ipsec_pfs      = var.alicloud_ipsec_pfs
      ipsec_lifetime = var.alicloud_ipsec_lifetime
    }
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Cato side — IPsec site + BGP peers + IKEv2 general-details PATCH + license.
# (Provider-agnostic; mirrors terraform-cato-ipsec-azure. Tunnel public_site_ip
# values are wired to the Alibaba gateway's two public IPs.)
# ─────────────────────────────────────────────────────────────────────────────

resource "cato_ipsec_site" "ipsec-site" {
  name                 = var.site_name
  site_type            = var.site_type
  description          = var.site_description
  native_network_range = var.native_network_range
  site_location        = local.cur_site_location
  ipsec = {
    primary = {
      destination_type  = var.primary_destination_type
      public_cato_ip_id = data.cato_allocatedIp.primary.items[0].id
      pop_location_id   = var.primary_pop_location_id
      tunnels = [
        {
          public_site_ip  = alicloud_vpn_gateway.this.internet_ip
          private_cato_ip = var.alicloud_enable_bgp ? var.primary_private_cato_ip : null
          private_site_ip = var.alicloud_enable_bgp ? var.primary_private_site_ip : null

          psk = var.primary_connection_shared_key == null ? random_password.shared_key_primary.result : var.primary_connection_shared_key
          last_mile_bw = {
            downstream = var.downstream_bw
            upstream   = var.upstream_bw
          }
        }
      ]
    }
    secondary = {
      destination_type  = var.secondary_destination_type
      public_cato_ip_id = data.cato_allocatedIp.secondary.items[0].id
      pop_location_id   = var.secondary_pop_location_id
      tunnels = [
        {
          public_site_ip  = alicloud_vpn_gateway.this.disaster_recovery_internet_ip
          private_cato_ip = var.alicloud_enable_bgp ? var.secondary_private_cato_ip : null
          private_site_ip = var.alicloud_enable_bgp ? var.secondary_private_site_ip : null
          psk             = var.secondary_connection_shared_key == null ? random_password.shared_key_secondary.result : var.secondary_connection_shared_key
          last_mile_bw = {
            downstream = var.downstream_bw
            upstream   = var.upstream_bw
          }
        }
      ]
    }
  }
}

# The Following 'terraform_data' resources allow us to set the specifics of the
# IPSEC configuration within Cato.  The Resource for this is being built, however,
# we need to set all of the information to make this module useful, especially
# when we aren't doing bgp and need to set the remote networks, or when default
# P1 & P2 settings don't match out of the box.

resource "terraform_data" "update_ipsec_site_details-bgp" {
  depends_on = [cato_ipsec_site.ipsec-site]
  count      = var.alicloud_enable_bgp ? 1 : 0

  triggers_replace = [
    cato_ipsec_site.ipsec-site.id,
    var.cato_authMessage_integrity,
    var.cato_authMessage_cipher,
    var.cato_authMessage_dhGroup,
    var.cato_initMessage_prf,
    var.cato_initMessage_integrity,
    var.cato_initMessage_cipher,
    var.cato_initMessage_dhGroup,
    var.cato_connectionMode
  ]

  provisioner "local-exec" {
    command = <<EOT
cat <<'PAYLOAD' | curl -k -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -H 'x-API-Key: ${var.token}' '${var.baseurl}' --data @-
${templatefile("${path.module}/templates/update_site_payload.json.tftpl", {
    account_id      = var.account_id
    site_id         = cato_ipsec_site.ipsec-site.id
    connection_mode = var.cato_connectionMode
    init_dh_group   = var.cato_initMessage_dhGroup
    init_cipher     = var.cato_initMessage_cipher
    init_integrity  = var.cato_initMessage_integrity
    init_prf        = var.cato_initMessage_prf
    auth_dh_group   = var.cato_authMessage_dhGroup
    auth_cipher     = var.cato_authMessage_cipher
    auth_integrity  = var.cato_authMessage_integrity
})}
PAYLOAD
EOT
}
}

resource "terraform_data" "update_ipsec_site_details-nobgp" {
  depends_on = [cato_ipsec_site.ipsec-site]
  count      = var.alicloud_enable_bgp ? 0 : 1

  triggers_replace = [
    cato_ipsec_site.ipsec-site.id,
    var.cato_authMessage_integrity,
    var.cato_authMessage_cipher,
    var.cato_authMessage_dhGroup,
    var.cato_initMessage_prf,
    var.cato_initMessage_integrity,
    var.cato_initMessage_cipher,
    var.cato_initMessage_dhGroup,
    var.cato_connectionMode,
    var.cato_local_networks
  ]

  provisioner "local-exec" {
    command = <<EOT
cat <<'PAYLOAD' | curl -k -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -H 'x-API-Key: ${var.token}' '${var.baseurl}' --data @-
${templatefile("${path.module}/templates/update_site_payload_nobgp.json.tftpl", {
    account_id          = var.account_id
    site_id             = cato_ipsec_site.ipsec-site.id
    connection_mode     = var.cato_connectionMode
    network_ranges_json = jsonencode(var.cato_local_networks)
    init_dh_group       = var.cato_initMessage_dhGroup
    init_cipher         = var.cato_initMessage_cipher
    init_integrity      = var.cato_initMessage_integrity
    init_prf            = var.cato_initMessage_prf
    auth_dh_group       = var.cato_authMessage_dhGroup
    auth_cipher         = var.cato_authMessage_cipher
    auth_integrity      = var.cato_authMessage_integrity
})}
PAYLOAD
EOT
}
}

# If BGP Enabled, build the BGP Configuration on the Cato Side.
resource "cato_bgp_peer" "primary" {
  count                    = var.alicloud_enable_bgp ? 1 : 0
  site_id                  = cato_ipsec_site.ipsec-site.id
  name                     = var.cato_primary_bgp_peer_name == null ? "${var.site_name}-primary-bgp-peer" : var.cato_primary_bgp_peer_name
  cato_asn                 = var.cato_bgp_asn
  peer_asn                 = var.alicloud_bgp_asn
  peer_ip                  = var.primary_private_site_ip
  metric                   = var.cato_primary_bgp_metric
  default_action           = var.cato_primary_bgp_default_action
  advertise_all_routes     = var.cato_primary_bgp_advertise_all
  advertise_default_route  = var.cato_primary_bgp_advertise_default_route
  advertise_summary_routes = var.cato_primary_bgp_advertise_summary_route
  md5_auth_key             = "" #Inserting Blank Value to Avoid State Changes

  bfd_settings = {
    transmit_interval = var.cato_primary_bgp_bfd_transmit_interval
    receive_interval  = var.cato_primary_bgp_bfd_receive_interval
    multiplier        = var.cato_primary_bgp_bfd_multiplier
  }
  lifecycle {
    ignore_changes = [
      summary_route
    ]
  }
}

resource "cato_bgp_peer" "backup" {
  count                    = var.alicloud_enable_bgp ? 1 : 0
  site_id                  = cato_ipsec_site.ipsec-site.id
  name                     = var.cato_secondary_bgp_peer_name == null ? "${var.site_name}-secondary-bgp-peer" : var.cato_secondary_bgp_peer_name
  cato_asn                 = var.cato_bgp_asn
  peer_asn                 = var.alicloud_bgp_asn
  peer_ip                  = var.secondary_private_site_ip
  metric                   = var.cato_secondary_bgp_metric
  default_action           = var.cato_secondary_bgp_default_action
  advertise_all_routes     = var.cato_secondary_bgp_advertise_all
  advertise_default_route  = var.cato_secondary_bgp_advertise_default_route
  advertise_summary_routes = var.cato_secondary_bgp_advertise_summary_route
  md5_auth_key             = "" #Inserting Blank Value to Avoid State Changes

  bfd_settings = {
    transmit_interval = var.cato_secondary_bgp_bfd_transmit_interval
    receive_interval  = var.cato_secondary_bgp_bfd_receive_interval
    multiplier        = var.cato_secondary_bgp_bfd_multiplier
  }

  lifecycle {
    ignore_changes = [
      summary_route
    ]
  }
}

resource "cato_license" "license" {
  depends_on = [cato_ipsec_site.ipsec-site]
  count      = var.license_id == null ? 0 : 1
  site_id    = cato_ipsec_site.ipsec-site.id
  license_id = var.license_id
  bw         = var.license_bw == null ? null : var.license_bw
}
