#Gets cidr and az from tfvars and loops for all subnets and creates them.
resource "aws_subnet" "main" {
  for_each = var.subnets
  vpc_id     = var.vpc_id
  cidr_block = each.value["cidr"]
  availability_zone = each.value["az"]
  tags = merge(var.tags, { Name = "${var.env}-${each.key}-subnet"})

}
#Creates route tables for all subnets
resource "aws_route_table" "main" {
  for_each = var.subnets
  vpc_id = var.vpc_id
  tags = merge(var.tags, { Name = "${var.env}-${each.key}-rt"})
  }
#Route tables will be associated to relevant subnets
resource "aws_route_table_association" "a" {
  for_each = var.subnets
  subnet_id      = lookup(lookup(aws_subnet.main, each.key, null), "id", null)
  route_table_id = lookup(lookup(aws_route_table.main, each.key, null), "id", null)
}

