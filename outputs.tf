#Why do we want only these 2 here? what are these doing? can i delete what happens? Output is only for display of info.
#why are we not displaying private subnets and peering id too?
output "subnets" {
  value = module.subnets
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

output "vpc_id" {
  value = aws_vpc.main.id
}