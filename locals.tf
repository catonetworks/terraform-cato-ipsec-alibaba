locals {
  vpc_id       = var.build_alicloud_vpc ? alicloud_vpc.this[0].id : var.alicloud_vpc_id
  vswitch_a_id = var.build_alicloud_vpc ? alicloud_vswitch.zone_a[0].id : var.alicloud_vswitch_a_id
  vswitch_b_id = var.build_alicloud_vpc ? alicloud_vswitch.zone_b[0].id : var.alicloud_vswitch_b_id
}
