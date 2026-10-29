#

1. Install terraform
2. run `ssh-key-generation.sh`
3. `cd local-kubernetes-infrastructure/terraform`
   `terraform init`
   `terraform fmt`
   `terraform validate`
   `terraform plan`
   `terraform apply`

# to do

- Create an Ansible playbook to configure libvirt on the host
- Install KVM/libvirt dependencies
- Ensure libvirt services are running
- Create and configure the Kubernetes lab storage pool
- Create and configure the libvirt virtual network
- Enable pool and network autostart
- Make the playbook idempotent so it can be safely rerun
- Use Terraform to provision the Kubernetes VMs
- Use Ansible to configure the VMs and install Kubernetes with kubeadm
