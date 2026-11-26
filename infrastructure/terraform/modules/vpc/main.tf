
# --------------------------------------------------
# VPC
# --------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  instance_tenancy = "default"

  lifecycle {
    precondition {
      condition     = local.subnet_cidrs_within_vpc
      error_message = "Every subnet CIDR must be contained within the VPC CIDR."
    }

    precondition {
      condition     = local.subnet_cidrs_non_overlapping
      error_message = "Subnet CIDR ranges must not overlap."
    }
  }

  tags = merge(
    var.tags,
    {
      Name      = var.name
      ManagedBy = "Terraform"
      Component = "networking"
    }
  )
}
# --------------------------------------------------
# Subnets
# --------------------------------------------------

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id               = aws_vpc.main.id
  cidr_block           = each.value.cidr
  availability_zone_id = each.value.availability_zone_id

  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name               = "${var.name}-${each.value.tier}-${each.value.availability_zone_id}"
      NetworkTier        = each.value.tier
      AvailabilityZoneId = each.value.availability_zone_id
    },
    each.value.tier == "public" ? {
      "kubernetes.io/role/elb" = "1"
    } : {},
    each.value.tier == "private-app" ? {
      "kubernetes.io/role/internal-elb" = "1"
      "karpenter.sh/discovery"          = "nextgen-discover-eks"
    } : {}
  )
}

# --------------------------------------------------
# Internet Gateway
# --------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name      = "${var.name}-igw"
      Component = "networking"
    }
  )
}

# --------------------------------------------------
# Elastic IPs for NAT Gateways
# --------------------------------------------------

resource "aws_eip" "nat" {
  for_each = local.public_subnets

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name      = "${var.name}-nat-eip-${each.value.availability_zone_id}"
      Component = "networking"
    }
  )
}

# --------------------------------------------------
# Public Route Table
# --------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name      = "${var.name}-public-rt"
      Component = "networking"
    }
  )
}

# Internet-bound traffic from public subnets goes to IGW
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate all public subnets with the public route table
resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

# --------------------------------------------------
# NAT Gateways
# --------------------------------------------------

resource "aws_nat_gateway" "this" {
  for_each = local.public_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.this[each.key].id

  connectivity_type = "public"

  depends_on = [
    aws_route.public_internet,
    aws_route_table_association.public
  ]

  tags = merge(
    var.tags,
    {
      Name      = "${var.name}-nat-${each.value.availability_zone_id}"
      Component = "networking"
    }
  )
}

resource "aws_route_table" "private_app" {
  for_each = local.private_app_subnets

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name      = "${var.name}-${each.value.tier}-rt-${each.value.availability_zone_id}"
      Component = "networking"
    }
  )
}

resource "aws_route_table_association" "private_app" {
  for_each = local.private_app_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private_app[each.key].id
}

resource "aws_route" "private_app_nat" {
  for_each = local.private_app_subnets

  route_table_id         = aws_route_table.private_app[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.this[
    "public-${each.value.availability_zone_id}"
  ].id
}


# --------------------------------------------------
# Isolated Database Route Table
# --------------------------------------------------

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name      = "${var.name}-private-db-rt"
      Component = "networking"
    }
  )
}

# Associate all database subnets with the isolated route table
resource "aws_route_table_association" "private_db" {
  for_each = local.private_db_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private_db.id
}


# --------------------------------------------------
# EKS Control Plane Route Table
# --------------------------------------------------

resource "aws_route_table" "eks_control_plane" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name      = "${var.name}-eks-control-plane-rt"
      Component = "networking"
    }
  )
}

# Associate all EKS control-plane subnets
resource "aws_route_table_association" "eks_control_plane" {
  for_each = local.eks_control_plane_subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.eks_control_plane.id
}



