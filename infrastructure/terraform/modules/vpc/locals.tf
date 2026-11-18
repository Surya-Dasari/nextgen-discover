
locals {
  subnet_tiers = {
    public = {
      cidrs = var.public_subnet_cidrs
    }

    private-app = {
      cidrs = var.private_app_subnet_cidrs
    }

    private-db = {
      cidrs = var.private_db_subnet_cidrs
    }

    eks-control-plane = {
      cidrs = var.eks_control_plane_subnet_cidrs
    }
  }

  # Build all subnet definitions dynamically
  subnets = merge([
    for tier, config in local.subnet_tiers : {
      for index, az_id in var.availability_zone_ids :
      "${tier}-${az_id}" => {
        tier                 = tier
        cidr                 = config.cidrs[index]
        availability_zone_id = az_id
      }
    }
  ]...)

  # Subnet groups
  public_subnets = {
    for key, subnet in local.subnets :
    key => subnet
    if subnet.tier == "public"
  }

  private_app_subnets = {
    for key, subnet in local.subnets :
    key => subnet
    if subnet.tier == "private-app"
  }

  private_db_subnets = {
    for key, subnet in local.subnets :
    key => subnet
    if subnet.tier == "private-db"
  }

  eks_control_plane_subnets = {
    for key, subnet in local.subnets :
    key => subnet
    if subnet.tier == "eks-control-plane"
  }

  # Collect every subnet CIDR
  all_subnet_cidrs = concat(
    var.public_subnet_cidrs,
    var.private_app_subnet_cidrs,
    var.private_db_subnet_cidrs,
    var.eks_control_plane_subnet_cidrs
  )

  # Convert the VPC address range into numeric boundaries
  vpc_start = sum([
    for index, octet in split(".", cidrhost(var.vpc_cidr, 0)) :
    tonumber(octet) * pow(256, 3 - index)
  ])

  vpc_end = sum([
    for index, octet in split(".", cidrhost(var.vpc_cidr, -1)) :
    tonumber(octet) * pow(256, 3 - index)
  ])

  # Calculate the numeric start and end addresses of each subnet
  subnet_ranges = [
    for cidr in local.all_subnet_cidrs : {
      cidr = cidr

      start = sum([
        for index, octet in split(".", cidrhost(cidr, 0)) :
        tonumber(octet) * pow(256, 3 - index)
      ])

      end = sum([
        for index, octet in split(".", cidrhost(cidr, -1)) :
        tonumber(octet) * pow(256, 3 - index)
      ])
    }
  ]

  # Verify that every subnet is contained inside the VPC
  subnet_cidrs_within_vpc = alltrue([
    for subnet in local.subnet_ranges :
    subnet.start >= local.vpc_start &&
    subnet.end <= local.vpc_end
  ])

  # Verify that no two subnet ranges overlap
  subnet_cidrs_non_overlapping = alltrue(flatten([
    for i, subnet_a in local.subnet_ranges : [
      for j, subnet_b in local.subnet_ranges :
      i >= j ? true : (
        subnet_a.end < subnet_b.start ||
        subnet_b.end < subnet_a.start
      )
    ]
  ]))
}

