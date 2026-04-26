provider "kubernetes" {
  host                   = data.aws_eks_cluster.myApp_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.myApp_eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.myApp_eks_cluster.token
}

# data "aws_eks_cluster" "myApp_eks_cluster" {
#   name = module.eks.cluster_name
# }

# data "aws_eks_cluster_auth" "myApp_eks_cluster" {
#   name = module.eks.cluster_name
# }
 
 module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name = "myApp-eks-cluster" 
  kubernetes_version = "1.33"

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.myApp-vpc.vpc_id
  subnet_ids               = module.myApp-vpc.private_subnets
  

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.medium"]

      min_size     = 2
      max_size     = 5
      desired_size = 4
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
    application  = "myApp"
  }
}