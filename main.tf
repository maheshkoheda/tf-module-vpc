#Creating vpc cidr same as env tfvars? with tag per make file environment dev or prod
resource "aws_vpc" "main" {
  cidr_block = var.cidr
  tags = merge(local.tags, { Name = "${var.env}-vpc"})
}
#Creating subnets using module subnets main.tf
module "subnets" {
  source = "./subnets"
  for_each = var.subnets
  subnets = each.value
  vpc_id = aws_vpc.main.id
  tags = local.tags
  env = var.env
}
#Creating internet gateway with tag per environment
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, { Name = "${var.env}-igw"})
}

#For all route table ids within public subnets attaching 0.0.0.0/0 internet gateway
#Check and see default vpc peering is not done here yet.
resource "aws_route" "igw" {
  for_each = lookup(lookup(module.subnets, "public", null), "route_table_ids", null)
  route_table_id            = each.value["id"]
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
#Elastic ip creation using count function which will give number of public subnet ids
resource "aws_eip" "ngw" {
  count = length(local.public_subnet_ids)
  domain   = "vpc"
}
#Nat gateway creation using count function which will give number of public subnet ids and allocates ids and tags
#Check for 1 or 2 natgateways and names are same
resource "aws_nat_gateway" "ngw" {
  count = length(local.public_subnet_ids)
  allocation_id = element(aws_eip.ngw.*.id, count.index)
  subnet_id     = element(local.public_subnet_ids, count.index)
  tags = merge(local.tags, { Name = "${var.env}-ngw"})

}
#For number of private route table ids attaching 0.0.0.0/0
#Check and see default vpc peering is not done here yet.
resource "aws_route" "ngw" {
  count = length(local.private_route_table_ids)
  route_table_id            = element(local.private_route_table_ids, count.index)
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = element(aws_nat_gateway.ngw.*.id, count.index)
}
#VPCs peering between selected env and default. And accepting peering.creating name as env-peer
resource "aws_vpc_peering_connection" "peering" {
  peer_vpc_id   = aws_vpc.main.id
  vpc_id        = var.default_vpc_id
  auto_accept = true
  tags = merge(local.tags, { Name = "${var.env}-peer"})
}
#Check for what does it do? Is this for default vpc peering only for all private routetable ids .
resource "aws_route" "peer" {
  count = length(local.private_route_table_ids)
  route_table_id            = element(local.private_route_table_ids, count.index)
  destination_cidr_block    = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

#resource "aws_route" "default-vpc-peer-entry" {
#  route_table_id            = var.default_vpc_route_table_id
#  destination_cidr_block    = var.cidr
#  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
#}
