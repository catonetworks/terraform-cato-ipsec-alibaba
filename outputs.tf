output "vpn_gateway_id" {
  description = "Alibaba VPN gateway ID."
  value       = alicloud_vpn_gateway.this.id
}

output "vpn_gateway_primary_public_ip" {
  description = "Primary (internet_ip) public IP of the Alibaba VPN gateway."
  value       = alicloud_vpn_gateway.this.internet_ip
}

output "vpn_gateway_secondary_public_ip" {
  description = "Secondary (disaster_recovery_internet_ip) public IP of the Alibaba VPN gateway."
  value       = alicloud_vpn_gateway.this.disaster_recovery_internet_ip
}

output "vpc_id" {
  description = "VPC ID (created or referenced)."
  value       = local.vpc_id
}

output "vpn_connection_id" {
  description = "Alibaba dual-tunnel VPN connection ID."
  value       = alicloud_vpn_connection.this.id
}

output "customer_gateway_primary_id" {
  description = "Primary customer gateway ID (Cato primary PoP)."
  value       = alicloud_vpn_customer_gateway.primary.id
}

output "customer_gateway_secondary_id" {
  description = "Secondary customer gateway ID (Cato secondary PoP)."
  value       = alicloud_vpn_customer_gateway.secondary.id
}

output "cato_site_id" {
  description = "Cato IPsec site ID."
  value       = cato_ipsec_site.ipsec-site.id
}

output "primary_connection_shared_key" {
  description = "PSK used for tunnel 1 (provided or generated)."
  value       = var.primary_connection_shared_key == null ? random_password.shared_key_primary.result : var.primary_connection_shared_key
  sensitive   = true
}

output "secondary_connection_shared_key" {
  description = "PSK used for tunnel 2 (provided or generated)."
  value       = var.secondary_connection_shared_key == null ? random_password.shared_key_secondary.result : var.secondary_connection_shared_key
  sensitive   = true
}

output "site_location" {
  description = "Resolved Cato site location."
  value       = local.cur_site_location
}
