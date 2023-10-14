#Why do we want only these 2 here? what are these doing? can i delete what happens?
output "subnet_ids" {
  value = aws_subnet.main
}

output "route_table_ids" {
  value = aws_route_table.main
}


