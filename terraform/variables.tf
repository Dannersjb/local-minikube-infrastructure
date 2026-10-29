variable "ssh_public_key_path" {
  description = "Path to the public SSH key for VM access"
  type        = string
  default     = "~/.ssh/kubernetes-lab.pub"
}