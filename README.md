# Local Kubernetes Cluster Setup

1. Install terraform
2. run `ssh-key-generation.sh`
3. `cd local-kubernetes-infrastructure/terraform`
4. `terraform apply`
5. `cd ..`
6. `ansible-playbook -i ansible/inventory.ini ansible/site.yml`

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
