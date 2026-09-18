# Derives the Cato site location from the Alibaba region via a static lookup map
# (mirrors terraform-cato-ipsec-azure's site_location_azure.tf). A user-supplied
# site_location object overrides the map.

locals {
  region_norm = lower(replace(var.alicloud_region, "-", ""))

  region_to_site_location = {
    cnguangzhou = { city = "Guangzhou", country_code = "CN", state_code = null, timezone = "Asia/Shanghai" }
    cnshanghai  = { city = "Shanghai", country_code = "CN", state_code = null, timezone = "Asia/Shanghai" }
    cnbeijing   = { city = "Beijing", country_code = "CN", state_code = null, timezone = "Asia/Shanghai" }
    cnshenzhen  = { city = "Shenzhen", country_code = "CN", state_code = null, timezone = "Asia/Shanghai" }
    cnhangzhou  = { city = "Hangzhou", country_code = "CN", state_code = null, timezone = "Asia/Shanghai" }
    cnchengdu   = { city = "Chengdu", country_code = "CN", state_code = null, timezone = "Asia/Shanghai" }
    cnhongkong  = { city = "Hong Kong", country_code = "HK", state_code = null, timezone = "Asia/Hong_Kong" }
  }

  use_user_location = anytrue([
    var.site_location.city != null,
    var.site_location.country_code != null,
    var.site_location.state_code != null,
    var.site_location.timezone != null,
  ])

  cur_site_location = local.use_user_location ? var.site_location : lookup(
    local.region_to_site_location,
    local.region_norm,
    { city = null, country_code = null, state_code = null, timezone = null }
  )
}
