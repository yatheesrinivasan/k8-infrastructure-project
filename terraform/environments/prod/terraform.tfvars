cluster_name = "my-k8s-prod"
environment  = "prod"

aws_region         = "us-west-2"
kubernetes_version = "1.27"

vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

node_groups = {
  main = {
    desired_size   = 3
    max_size       = 6
    min_size       = 2
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    ami_type       = "AL2_x86_64"
  }
  
  spot = {
    desired_size   = 2
    max_size       = 4
    min_size       = 1
    instance_types = ["t3.medium", "t3.large"]
    capacity_type  = "SPOT"
    disk_size      = 30
    ami_type       = "AL2_x86_64"
  }
}