resource "aws_launch_template" "workers" {
  name_prefix = "${var.project_name}-eks-workers-"

  vpc_security_group_ids = [
    var.worker_security_group_id,
    aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  ]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  update_default_version = true

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name      = "${var.project_name}-eks-worker"
      Component = "EKS"
    })
  }

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks-workers-launch-template"
    Component = "EKS"
  })
}

# --------------------------------------------------
# EKS Observability Worker Launch Template
# --------------------------------------------------

resource "aws_launch_template" "observability_workers" {
  name_prefix = "${var.project_name}-eks-observability-"

  vpc_security_group_ids = [
    var.worker_security_group_id,
    aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  ]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.observability_node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  update_default_version = true

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name      = "${var.project_name}-eks-observability-worker"
      Component = "EKS-Observability"
    })
  }

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks-observability-launch-template"
    Component = "EKS-Observability"
  })
}
