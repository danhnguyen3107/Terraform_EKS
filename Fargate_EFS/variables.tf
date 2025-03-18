variable "aws_region" {
 type        = string
 description = "Region in which resources are created"
 default     = "us-west-1"
}
 
variable "eks_vpc_cidr" {
 type        = string
 description = "CIDR block for the VPC"
 default     = "10.0.0.0/16"
}
 
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


variable "eks_cluster_role_name" {
 type        = string
 description = "Name of the EKS Cluster Role"
 default     = "eks-cluster-role"
}

variable "eks_worker_role_name" {
 type        = string
 description = "Name of the EKS Worker Role"
 default     = "eks-worker-role"
}


variable "bootstrap_self_managed_addons" {
 type        = bool
 description = "Addon for EKS Cluster"
 default     = true
}

variable "user_account" {
 type        = string
 description = "user account arn"
 default     = "your user account arn" //"arn:aws:iam::XXXXXXXXXX:root"
}

variable "account_id" {
 type        = string
 description = "user account arn"
 default     = "your user id arn" //"arn:aws:iam::XXXXXXXXXX"
}




variable "eks_fargate_role_name" {
 type        = string
 description = "Name of the EKS Fargate Role"
 default     = "eks-fargate-pod-execution-role"
}

variable "eks_fargate_profile_name" {
 type        = string
 description = "Name of the EKS Fargate Profile"
 default     = "data-test"
}
