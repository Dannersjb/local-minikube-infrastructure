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

# Download the base Ubuntu cloud image once.
resource "libvirt_volume" "ubuntu_base" {
  name = "ubuntu-noble-base.qcow2"
  pool = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = local.ubuntu_image_url
    }
  }
}

# Create a separate writable disk for each node.
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

  backing_store = {
    path = libvirt_volume.ubuntu_base.path
    target = {
      format = {
        type = "qcow2"
      }
    }
  }
}

# Generate cloud-init configuration for each VM.
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

# Import each cloud-init image into the libvirt storage pool.
resource "libvirt_volume" "node_init_iso" {
  for_each = local.nodes

  name = "${each.key}-cloudinit.iso"
  pool = "default"
  target = {
    format = {
      type = "iso"
    }
  }

  create = {
    content = {
      url = libvirt_cloudinit_disk.node_init[each.key].path
    }
  }

  depends_on = [libvirt_cloudinit_disk.node_init]
}

# Create the VMs.
resource "libvirt_domain" "node" {
  for_each = local.nodes

  name        = each.key
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.vcpu

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"

    boot_devices = [
      {
        dev = "hd"
      }
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
        wait_for_ip = {
          timeout = 300
          source  = "lease"
        }
      }
    ]
  }
}