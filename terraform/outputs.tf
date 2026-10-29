output "vm_names" {
  description = "Names of the Kubernetes nodes"
  value       = { for name, node in libvirt_domain.node : name => node.name }
}

data "libvirt_domain_interface_addresses" "node" {
  for_each = libvirt_domain.node

  domain = each.value.name
  source = "lease"
}

output "vm_ips" {
  description = "IP addresses reported by libvirt DHCP leases"
  value = {
    for name, info in data.libvirt_domain_interface_addresses.node :
    name => try(info.interfaces[0].addrs[0].addr, "IP not detected")
  }
}