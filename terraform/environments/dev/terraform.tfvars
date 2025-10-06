cluster_name = "my-k8s-dev"
environment  = "dev"

aws_region         = "us-west-2"
kubernetes_version = "1.27"

vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b"]

node_groups = {
  main = {
    desired_size   = 2
    max_size       = 3
    min_size       = 1
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
    ami_type       = "AL2_x86_64"
  }
}