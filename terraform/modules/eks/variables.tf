variable "project_name"       { type = string }
variable "kubernetes_version" { type = string  default = "1.29" }
variable "private_subnet_ids" { type = list(string) }
variable "node_instance_type" { type = string  default = "t3.medium" }
variable "desired_nodes"      { type = number  default = 2 }
variable "min_nodes"          { type = number  default = 1 }
variable "max_nodes"          { type = number  default = 4 }
