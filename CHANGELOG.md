# Changelog

## 0.1.0 (2026-09-18)

### Features
- Initial release. Creates a Cato IPsec site (primary + secondary tunnels) with
  optional BGP and the Alibaba Cloud side of the connection — VPC + two gateway
  vSwitches (optional build-or-reference), a public dual-zone HA VPN gateway
  (two public IPs), two customer gateways (Cato PoPs), and a single dual-tunnel
  `alicloud_vpn_connection` with per-tunnel BGP. Mirrors the conventions of
  `terraform-cato-ipsec-azure`, including the IKEv2 general-details API PATCH and
  the region→site-location lookup.
