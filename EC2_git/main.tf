
provider "aws" {
    region = "us-west-1"  # Set your desired AWS region
}

resource "aws_vpc" "eks_vpc_deploy" {
 cidr_block = "10.0.0.0/16"
 enable_dns_hostnames = true
 tags = {
   Name = "EKS VPC"
 }
}

resource "aws_subnet" "public_subnets" {
 count             = length(var.public_subnet_cidrs)
 vpc_id            = aws_vpc.eks_vpc_deploy.id
 cidr_block        = element(var.public_subnet_cidrs, count.index) 
 availability_zone = element(var.azs, count.index)
 map_public_ip_on_launch = true
 
 tags = {
   Name = "Public Subnet ${count.index + 1}",
   "kubernetes.io/role/elb" = "1",
   "kubernetes.io/cluster/eks-cluster" = "shared",
  #  "kubernetes.io/role/internal-elb" = "1"
 }
}
 


resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.eks_vpc_deploy.id
 
 tags = {
   Name = "Project VPC IG"
 }
}


resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.eks_vpc_deploy.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "2nd Route Table"
 }
}


resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}

# -----------------------------------Security Group for EKS Cluster--------------------------------------------------

resource "aws_security_group" "eks_cluster_sg" {
  name = "eks_cluster_sg"
  vpc_id = aws_vpc.eks_vpc_deploy.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   tags = {
 
   "kubernetes.io/role/elb" = "1",
   "kubernetes.io/cluster/eks-cluster" = "shared"
 }
}


# -----------------------------------EKS Cluster Role Creation--------------------------------------------------

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
        Action    = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "eks_cluster_storage_policy" {
  role = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_compute_policy" {
  role = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_load_balancing_policy" {
  role = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_networking_policy" {
  role = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
}


# -----------------------------------EKS Node Role Creation--------------------------------------------------
resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "AmazonEBSCSIDriver_Policy"
  description = "Custom policy for EBS CSI driver"
  policy      = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:ModifyVolume",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInstances",
                "ec2:DescribeSnapshots",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumesModifications"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:snapshot/*"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": [
                        "CreateVolume",
                        "CreateSnapshot"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteTags"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:volume/*",
                "arn:aws:ec2:*:*:snapshot/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestTag/CSIVolumeName": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/CSIVolumeName": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteVolume"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/kubernetes.io/created-for/pvc/name": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
                }
            }
        }
    ]
}
POLICY
}
resource "aws_iam_policy" "efs_csi_policy" {
  name        = "AmazonEFSCSIDriver_Policy"
  description = "Custom policy for EFS CSI driver"
  policy      = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowDescribe",
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:DescribeAccessPoints",
                "elasticfilesystem:DescribeFileSystems",
                "elasticfilesystem:DescribeMountTargets",
                "ec2:DescribeAvailabilityZones"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowCreateAccessPoint",
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:CreateAccessPoint"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/efs.csi.aws.com/cluster": "false"
                },
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": "efs.csi.aws.com/cluster"
                }
            }
        },
        {
            "Sid": "AllowTagNewAccessPoints",
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:TagResource"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "elasticfilesystem:CreateAction": "CreateAccessPoint"
                },
                "Null": {
                    "aws:RequestTag/efs.csi.aws.com/cluster": "false"
                },
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": "efs.csi.aws.com/cluster"
                }
            }
        },
        {
            "Sid": "AllowDeleteAccessPoint",
            "Effect": "Allow",
            "Action": "elasticfilesystem:DeleteAccessPoint",
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/efs.csi.aws.com/cluster": "false"
                }
            }
        }
    ]
}
POLICY
}



resource "aws_iam_role" "eks_worker_role" {
  name = "eks-worker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = [
          "sts:AssumeRole"
          
          ]
      }
    ]
  })

}

resource "aws_iam_role" "eks_worker_role_auto" {
  name = "eks-worker-role_auto"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = [
          "sts:AssumeRole"
          ]
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "worker_container_registry_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "worker_cni_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


resource "aws_iam_role_policy_attachment" "worker_ebs_csi_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
}

resource "aws_iam_role_policy_attachment" "worker_efs_csi_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = aws_iam_policy.efs_csi_policy.arn
}



resource "aws_iam_role_policy_attachment" "worker_node_auto_policies" {
  count = length([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    aws_iam_policy.ebs_csi_policy.arn,
    aws_iam_policy.efs_csi_policy.arn,
  ])

  policy_arn = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    aws_iam_policy.ebs_csi_policy.arn,
    aws_iam_policy.efs_csi_policy.arn,
  ][count.index]
  role = aws_iam_role.eks_worker_role_auto.name
}
# -----------------------------------EKS Cluster Creation--------------------------------------------------

resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids = aws_subnet.public_subnets[*].id
    security_group_ids = [aws_security_group.eks_cluster_sg.id]

  }
  storage_config {
    block_storage {
      enabled = true
    }
  }

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.eks_worker_role_auto.arn
  }

  kubernetes_network_config {
    ip_family = "ipv4"
    service_ipv4_cidr = "172.16.0.0/16"

    elastic_load_balancing {
      enabled = true
    }
  }

  # Set access config for Auto Mode
  access_config {
    authentication_mode  = "API_AND_CONFIG_MAP" # Required for Auto Mode
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# Addons for the EKS Cluster
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"

  tags = {
    Name = "vpc-cni-addon"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "kube-proxy"
  

  tags = {
    Name = "kube-proxy-addon"
  }
}

# resource "aws_eks_addon" "coredns" {
#   cluster_name = aws_eks_cluster.eks_cluster.name
#   addon_name   = "coredns"
#   addon_version = "v1.11.3-eksbuild.2"

#   tags = {
#     Name = "coredns-addon"
#   }
# }

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "eks-pod-identity-agent"


  tags = {
    Name = "eks-pod-identity-agent-addon"
  }
}

# -----------------------------------EKS Entry Creation For Root--------------------------------------------------
resource "aws_eks_access_entry" "root_access_entry" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  principal_arn     = var.user_account
  type              = "STANDARD"

}

resource "aws_eks_access_policy_association" "root_access_policy" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.user_account

  access_scope {
    type       = "cluster"
    
   
  }
}


# -----------------------------------EKS Create Node Group--------------------------------------------------
# data "aws_security_group" "eks_default_sg" {
#   filter {
#     name   = "tag:aws:eks:cluster-name"
#     values = [aws_eks_cluster.eks_cluster.name]
#   }
# }
resource "aws_security_group_rule" "allow_all_inbound" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  # security_group_id = data.aws_security_group.eks_default_sg.id
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_eks_node_group" "eks_node_group_db" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "db"
  node_role_arn   = aws_iam_role.eks_worker_role.arn
  subnet_ids      = aws_subnet.public_subnets[*].id
  disk_size = 30
  instance_types  = var.instance_types_node_group
  ami_type       = var.ami_types_node_group
  capacity_type  = "ON_DEMAND"

  
  labels = {
    "db" = "database"
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.worker_cni_policy,
    aws_iam_role_policy_attachment.worker_container_registry_policy,
    aws_iam_role_policy_attachment.worker_ebs_csi_policy,
    aws_iam_role_policy_attachment.worker_efs_csi_policy,
  ]
}


resource "aws_eks_node_group" "eks_node_group_web" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "web"
  node_role_arn   = aws_iam_role.eks_worker_role.arn
  subnet_ids      = aws_subnet.public_subnets[*].id
  disk_size = 30
  instance_types  = var.instance_types_node_group
  ami_type       = var.ami_types_node_group
  capacity_type  = "ON_DEMAND"

  # remote_access {
  #   source_security_group_ids = [aws_security_group.eks_cluster_sg.id]
  # }
  
  labels = {
    "web" = "python-django"
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.worker_cni_policy,
    aws_iam_role_policy_attachment.worker_container_registry_policy,
    aws_iam_role_policy_attachment.worker_ebs_csi_policy,
    aws_iam_role_policy_attachment.worker_efs_csi_policy,
  ]
}