# Solution: Reusable VPC Module

## Directory Structure
```
terraform-vpc-module/
├── main.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```

## File Contents

### versions.tf
```hcl
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}
```

### variables.tf
```hcl
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### main.tf
```hcl
provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "main-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "main-igw"
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  vpc = true

  tags = merge(var.tags, {
    Name = "nat-eip"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(aws_subnet.public[*].id, 0)  # First public subnet

  tags = merge(var.tags, {
    Name = "main-nat"
  })
}

# Create Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "public-subnet-${count.index + 1}"
  })
}

# Create Private Subnets
resource "aws_subnet" "private" {
  count         = length(var.private_subnet_cidrs)
  vpc_id        = aws_vpc.this.id
  cidr_block    = element(var.private_subnet_cidrs, count.index)
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "private-subnet-${count.index + 1}"
  })
}

# Route Tables
# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "public-rt"
  })
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "private-rt"
  })
}

# Associate subnets with route tables
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private.id
}

# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}
```

## Usage Example
To use this module in another Terraform configuration:

```hcl
module "vpc" {
  source = "./terraform-vpc-module"

  vpc_cidr       = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  region         = "us-west-2"
  tags = {
    Environment = "prod"
    Team        = "platform"
  }
}
```

## Verification
After applying the module, you should see:
- A VPC with the specified CIDR block
- Two public subnets with auto-assign public IP enabled
- Two private subnets without public IP
- An Internet Gateway attached to the VPC
- A NAT Gateway in the first public subnet
- Public subnets routing to the Internet Gateway
- Private subnets routing to the NAT Gateway