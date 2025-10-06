cluster_name = "yathee-k8s-dev"  # Changed from generic name
environment  = "dev"

aws_region         = "us-west-2"
kubernetes_version = "1.27"  # Could upgrade to 1.28 but 1.27 is stable

vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b"]

node_groups = {
  main = {
    desired_size   = 2
    max_size       = 3
    min_size       = 1
    instance_types = ["t3.medium"]  # t3.small was too small for the monitoring stack
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
    ami_type       = "AL2_x86_64"
    # TODO: Test with Bottlerocket AMI for better security
  }
}