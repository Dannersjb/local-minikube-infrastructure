locals {
  nodes = {
    control-plane = {
      memory = 4096
      vcpu   = 2
      disk   = 15
    }
    worker-1 = {
      memory = 2048
      vcpu   = 2
      disk   = 10
    }
    worker-2 = {
      memory = 2048
      vcpu   = 2
      disk   = 10
    }
  }

  ubuntu_image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

# One independent Ubuntu disk per VM.
resource "libvirt_volume" "node_disk" {
  for_each = local.nodes

  name = "${each.key}.qcow2"
  pool = "default"

  target = {
    format = {
      type = "qcow2"
    }
  }

  capacity = each.value.disk * 1024 * 1024 * 1024

  create = {
    content = {
      url = local.ubuntu_image_url
    }
  }
}

# Cloud-init configuration for each VM.
resource "libvirt_cloudinit_disk" "node_init" {
  for_each = local.nodes

  name = "${each.key}-cloudinit"

  meta_data = yamlencode({
    instance-id    = each.key
    local-hostname = each.key
  })

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    hostname       = each.key
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })
}

# Store each cloud-init ISO in libvirt.
resource "libvirt_volume" "node_init_iso" {
  for_each = local.nodes

  name = "${each.key}-cloudinit.iso"
  pool = "default"

  create = {
    content = {
      url = libvirt_cloudinit_disk.node_init[each.key].path
    }
  }

  depends_on = [libvirt_cloudinit_disk.node_init]
}

# Three Ubuntu VMs.
resource "libvirt_domain" "node" {
  for_each = local.nodes

  name        = each.key
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.vcpu
  running     = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"

    boot_devices = [
      { dev = "hd" }
    ]
  }

  devices = {
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.node_disk[each.key].name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = "default"
            volume = libvirt_volume.node_init_iso[each.key].name
          }
        }
        target = {
          dev = "sdb"
          bus = "sata"
        }
      }
    ]

    interfaces = [
      {
        type = "network"
        source = {
          network = {
            network = "default"
          }
        }
        model = {
          type = "virtio"
        }
      }
    ]

    consoles = [
      {
        type = "pty"
        target = {
          type = "serial"
          port = 0
        }
      }
    ]
  }
}