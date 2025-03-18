output "vpc_id" {
    description = "The ID of the VPC"
    value       = aws_vpc.eks_vpc_deploy.id
}

output "oidc_provider" {
    description = "The OIDC provider for the EKS cluster"
    value       = aws_iam_openid_connect_provider.eks_oicd
}

output "load_balancer_role" {
    description = "The IAM role for the load balancer"
    value       = aws_iam_role.load_balancer_controller_role
}

output "ebs_role" {
    description = "The IAM role for EBS"
    value       = aws_iam_role.eks_efs_role
}
