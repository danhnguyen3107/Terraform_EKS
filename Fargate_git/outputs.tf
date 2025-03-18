output "vpc_id" {
    description = "The ID of the VPC"
    value       = aws_vpc.eks_vpc_deploy.id
}