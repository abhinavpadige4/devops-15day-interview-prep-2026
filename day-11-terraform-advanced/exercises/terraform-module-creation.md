# Exercise: Create a Reusable VPC Module

## Objective
Create a Terraform module that provisions a VPC with public and private subnets, which can be reused across different environments.

## Requirements
1. Create a module that provisions:
   - A VPC with configurable CIDR block
   - Public subnets (at least 2)
   - Private subnets (at least 2)
   - Internet Gateway for public subnets
   - NAT Gateway for private subnets
   - Route tables for public and private subnets

2. The module should accept the following variables:
   - `vpc_cidr`: CIDR block for the VPC
   - `public_subnet_cidrs`: List of CIDR blocks for public subnets
   - `private_subnet_cidrs`: List of CIDR blocks for private subnets
   - `region`: AWS region
   - `tags`: Map of tags to apply to resources

3. The module should output:
   - `vpc_id`: The ID of the created VPC
   - `public_subnet_ids`: List of public subnet IDs
   - `private_subnet_ids`: List of private subnet IDs

## Starter Code
Create the following directory structure:
```
terraform-vpc-module/
├── main.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```

## Hints
- Use the AWS provider
- Remember to create separate route tables for public and private subnets
- For NAT Gateway, you'll need an Elastic IP
- Consider using the `count` meta-argument for multiple subnets