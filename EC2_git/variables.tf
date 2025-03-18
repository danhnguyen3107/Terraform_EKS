variable "public_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.0.1.0/24",  "10.0.2.0/24"]
}
 
variable "private_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["10.0.4.0/24", "10.0.5.0/24"]
}


variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["us-west-1a", "us-west-1c"]
}

variable "bootstrap_self_managed_addons" {
 type        = bool
 description = "Addon for EKS Cluster"
 default     = true
}

variable "user_account" {
 type        = string
 description = "user account arn"
 default     = "your user account arn"
}


variable "instance_types_node_group" {
 type        = list(string)
 description = "List of Instance type for Node Group"
 default     = ["t3.medium"]
  
}

variable "ami_types_node_group" {
 type        = string
 description = "List of AMI type for Node Group"
 default     = "AL2_x86_64"
  
}