# Terraform_EKS
Configure EKS cluster with Terraform


## Create EKS cluster with ec2 instance 
Replace the `default` in `EC2_git/variables.tf` 
```
variable "user_account" {
 type        = string
 description = "user account arn"
 default     = "your user account arn" //"arn:aws:iam::XXXXXXXXXX:root"
}


```


## Create EKS cluster with fargate instance 
Change the `default` in `Fargate_git/variables.tf` 

```
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
```

change `account_id` in `Fargate_git\Kubernetes\serviceAccount-eks.yaml`

``` 
 annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::account_id:role/AmazonEKSLoadBalancerControllerRole
```