data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "eks_cluster_vpc" {
  cidr_block           = local.vpc.cidr
  instance_tenancy     = local.vpc.tenancy
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.vpc.name}"
  }
}

resource "aws_subnet" "eks_cluster_vpc_public_subnets" {
  count = local.vpc.num_public_subnets

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.vpc.cidr, 8, count.index)
  vpc_id                  = aws_vpc.eks_cluster_vpc.id
  map_public_ip_on_launch = false

  tags = {
    Name = "public-subnet${count.index}-${data.aws_availability_zones.available.zone_ids[count.index]}"
  }
}

resource "aws_subnet" "eks_cluster_vpc_private_subnets" {
  count = local.vpc.num_private_subnets

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.vpc.cidr, 8, count.index + 10)
  vpc_id            = aws_vpc.eks_cluster_vpc.id

  tags = {
    Name = "private-subnet${count.index}-${data.aws_availability_zones.available.zone_ids[count.index]}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_cluster_vpc.id

  tags = {
    Name = "${local.vpc.name}-igw"
  }
}

resource "aws_eip" "eip" {

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "${local.vpc.name}-natgw-eip"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.eks_cluster_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.vpc.name}-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count = local.vpc.num_public_subnets

  subnet_id      = aws_subnet.eks_cluster_vpc_public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id

  depends_on = [
    aws_subnet.eks_cluster_vpc_public_subnets,
    aws_route_table.public_rt
  ]
}

resource "aws_nat_gateway" "natgw" {
  allocation_id     = aws_eip.eip.id
  connectivity_type = "public"
  subnet_id         = aws_subnet.eks_cluster_vpc_public_subnets[0].id

  tags = {
    Name = "${local.vpc.name}-natgw"
  }

  depends_on = [
    aws_internet_gateway.igw,
    aws_eip.eip
  ]
}

# add a default route in the main route table, which sends traffic to the NAT gateway.
# the main route table will be attached to the private subnets
resource "aws_default_route_table" "default_rt" {
  default_route_table_id = aws_vpc.eks_cluster_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "${local.vpc.name}-main-rt"
  }

  depends_on = [
    aws_nat_gateway.natgw
  ]
}
