# Day 10: Terraform Basics

## Topics Covered
- Terraform architecture and workflow
- Providers and resources
- Input variables and output values
- Local values and data sources
- Resource addressing and dependencies
- State management basics
- Terraform CLI commands
- Version constraints and providers
- Basic functions and expressions
- Resource lifecycle
- Provisioners (limited use)
- Terraform Cloud basics

## Resources
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)
- [Terraform Providers](https://registry.terraform.io/browse/providers)
- [Terraform Registry](https://registry.terraform.io/)
- [Learn Terraform Tutorials](https://developer.hashicorp.com/terraform/tutorials)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build)
- [Terraform Associate Study Guide](https://learn.hashicorp.com/tutorials/terraform/associate-study-guide)

## Hands-on Exercises

### Exercise 1: Terraform Installation and Setup
1. Install Terraform CLI
2. Verify installation and version
3. Set up Terraform workspace
4. Configure provider credentials
5. Initialize Terraform project

### Exercise 2: Providers and Resources
1. Create Terraform configuration with providers
2. Define resources (compute, storage, networking)
3. Understand resource lifecycle
4. Use resource arguments and attributes
5. Practice terraform fmt, validate, plan

### Exercise 3: Variables and Outputs
1. Define input variables with types and defaults
2. Use variable validation and constraints
3. Define output values
4. Use sensitive variables
5. Practice terraform console and output inspection

### Exercise 4: State Management and Data Sources
1. Understand Terraform state file
2. Practice state commands (list, show, replace)
3. Use data sources to query existing resources
4. Implement remote state basics
5. Practice state locking concepts

### Exercise 5: Modules and Reusability
1. Create reusable Terraform modules
2. Use module sources (local, registry, git)
3. Pass variables to modules
4. Get outputs from modules
5. Practice module versioning

## Solutions

<details>
<summary>Exercise 1 Solutions: Terraform Installation and Setup</summary>

```bash
# 1. Install Terraform CLI
echo "Installing Terraform CLI..."
# Method 1: Using HashiCorp's official repository (recommended)
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install -y terraform

# Alternative: Direct download
# TERRAFORM_VERSION="1.5.7"
# wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
# unzip terraonform_${TERRAFORM_VERSION}_linux_amd64.zip
# sudo mv terraform /usr/local/bin/
# terraform --version

# Method 2: Using package managers
# macOS with Homebrew: brew tap hashicorp/tap && brew install hashicorp/tap/terraform
# Windows with Chocolatey: choco install terraform
# Windows with Scoop: scoop install terraform

# 2. Verify installation and version
echo "Verifying Terraform installation..."
terraform --version
terraform version -json | jq .

# 3. Set up Terraform workspace
echo "Setting up Terraform workspace..."
mkdir -p terraform-basics
cd terraform-basics

# Create basic Terraform configuration
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Simple resource for testing
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t2.micro"

  tags = {
    Name = "terraform-example"
  }
}
EOF

# 4. Configure provider credentials
echo "Configuring AWS provider credentials..."
echo "# Method 1: AWS CLI credentials (recommended)"
echo "aws configure"
echo "# AWS Access Key ID [None]: YOUR_ACCESS_KEY"
echo "# AWS Secret Access Key [None]: YOUR_SECRET_KEY"
echo "# Default region name [None]: us-east-1"
echo "# Default output format [None]: json"
echo ""
echo "# Method 2: Environment variables"
echo "export AWS_ACCESS_KEY_ID=\"YOUR_ACCESS_KEY\""
echo "export AWS_SECRET_ACCESS_KEY=\"YOUR_SECRET_KEY\""
echo "export AWS_DEFAULT_REGION=\"us-east-1\""
echo ""
echo "# Method 3: Shared credentials file"
echo "mkdir -p ~/.aws"
echo "cat > ~/.aws/credentials << EOF"
echo "[default]"
echo "aws_access_key_id = YOUR_ACCESS_KEY"
echo "aws_secret_access_key = YOUR_SECRET_KEY"
echo "EOF"
echo ""
echo "# Method 4: Assume role (for cross-account access)"
echo "export AWS_PROFILE=production"
echo "# or"
echo "export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/terraform-role"
echo "export AWS_WEB_IDENTITY_TOKEN_FILE=/tmp/token.txt"

# 5. Initialize Terraform project
echo "Initializing Terraform project..."
terraform init

# Verify initialization
ls -la .terraform/
echo "Providers installed:"
ls -la .terraform/plugins/

# Check if initialization was successful
if [ -f .terraform/lock.hcl ]; then
  echo "✅ Terraform initialized successfully"
else
  echo "❌ Terraform initialization failed"
fi

# Cleanup
cd ..
rm -rf terraform-basics
```
</details>

<details>
<summary>Exercise 2 Solutions: Providers and Resources</summary>

```bash
# 1. Create Terraform configuration with providers
echo "Creating multi-provider Terraform configuration..."
mkdir -p terraform-providers
cd terraform-providers

cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Configure providers
provider "aws" {
  region = var.aws_region
}

provider "random" {
  # No configuration needed
}

provider "local" {
  # No configuration needed
}

# 2. Define resources (compute, storage, networking)
echo "Defining various AWS resources..."

# VPC and networking
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, 0)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security groups
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_blocks]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_blocks]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-web-sg"
  }
}

# Compute resources
resource "aws_instance" "web" {
  count                = var.web_instance_count
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "<h1>Hello from ${var.environment}</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "${var.environment}-web-server-${count.index}"
  }
}

# Load balancer
resource "aws_lb" "web" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }

  tags = {
    Name = "${var.environment}-tg"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Register instances with target group
resource "aws_lb_target_group_attachment" "web" {
  count              = var.web_instance_count
  target_group_arn   = aws_lb_target_group.web.arn
  target_id          = aws_instance.web[count.index].id
  target_port        = 80
}

# Storage resources
resource "aws_s3_bucket" "logs" {
  bucket = "${var.environment}-logs-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "${var.environment}-logs-bucket"
  }
}

resource "aws_s3_bucket_object" "log_file" {
  bucket = aws_s3_bucket.logs.id
  key    = "application.log"
  source = "log-file-content.txt"

  etag = filemd5("log-file-content.txt")
}

# Database resources
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier         = "${var.environment}-db-instance"
  engine             = "mysql"
  engine_version     = "5.7"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  name               = var.db_name
  username           = var.db_username
  password           = var.db_password
  skip_final_snapshot = true
  subnet_group_name  = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "${var.environment}-db-instance"
  }
}

# 3. Understand resource lifecycle
echo "Demonstrating resource lifecycle configurations..."
cat > lifecycle-examples.tf << 'EOF'
# Create before destroy
resource "aws_instance" "create_before_destroy" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "create-before-destroy"
  }
}

# Prevent destruction
resource "aws_instance" "prevent_destroy" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "prevent-destroy"
  }
}

# Ignore changes to specific attributes
resource "aws_instance" "ignore_changes" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  lifecycle {
    ignore_changes = [
      tags,
      user_data
    ]
  }

  tags = {
    Name = "ignore-changes-example"
    Environment = "testing"
  }
}
EOF

# 4. Use resource arguments and attributes
echo "Demonstrating resource arguments and attributes..."
cat > resource-attributes.tf << 'EOF'
# Data sources to get information about existing resources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Resource with complex arguments
resource "aws_instance" "complex_example" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id

  # Credit specification for burstable instances
  credit_specification {
    cpu_credits = "standard"
  }

  # Ephemeral storage
  ephemeral_block_device {
    device_name = "/dev/sdb"
    virtual_name = "ephemeral0"
  }

  # Root block device customization
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    iops        = 3000
    throughput  = 125
  }

  tags = {
    Name = "complex-resource-example"
    Environment = var.environment
    Team        = var.team
  }
}

# Output resource attributes for use elsewhere
output "web_instance_ids" {
  description = "IDs of web instances"
  value       = aws_instance.web[*].id
}

output "web_instance_public_ips" {
  description = "Public IPs of web instances"
  value       = aws_instance.web[*].public_ip
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.web.dns_name
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
}

# 5. Practice terraform fmt, validate, plan
echo "Practicing Terraform CLI commands..."
terraform fmt
terraform validate
terraform plan -var="environment=dev" -var="web_instance_count=2"

# Show what would be created
echo "Resources that would be created:"
terraform plan -var="environment=dev" -var="web_instance_count=2" -no-color | grep -E "(+ create|# aws_)"

# Cleanup
cd ..
rm -rf terraform-providers
```
</details>

<details>
<summary>Exercise 3 Solutions: Variables and Outputs</summary>

```bash
# 1. Define input variables with types and defaults
echo "Creating variables.tf with various variable types..."
cat > variables.tf << 'EOF'
# String variables
variable "environment" {
  description = "Environment for resources (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Instance type must be one of: t2.micro, t2.small, t2.medium, t3.micro, t3.small."
  }
}

# Number variables
variable "web_instance_count" {
  description = "Number of web instances to deploy"
  type        = number
  default     = 2
  validation {
    condition     = var.web_instance_count > 0 && var.web_instance_count <= 10
    error_message = "Web instance count must be between 1 and 10."
  }
}

variable "port" {
  description = "Port number for application"
  type        = number
  default     = 8080
  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port number must be between 1 and 65535."
  }
}

# Boolean variables
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "create_db" {
  description = "Whether to create database instance"
  type        = bool
  default     = true
}

# List variables
variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["10.0.0.0/8", "192.168.0.0/16"]
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Map variables
variable "instance_type_by_size" {
  description = "Map of instance sizes to types"
  type        = map(string)
  default = {
    small   = "t2.micro"
    medium  = "t2.medium"
    large   = "t2.large"
    xlarge  = "t2.xlarge"
  }
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Team        = "DevOps"
    Project     = "Terraform-Learning"
  }
}

# Object variables (complex type)
variable "database_config" {
  description = "Database configuration object"
  type = object({
    name     = string
    username = string
    password = string
    engine   = string
    version  = string
    size     = string
  })
  default = {
    name     = "myappdb"
    username = "admin"
    password = "changeme123"
    engine   = "postgres"
    version  = "13"
    size     = "db.t3.micro"
  }
}

# Tuple variables
variable "port_range" {
  description = "Range of ports for load balancer"
  type        = tuple([number, number])
  default     = [80, 443]
}

# 2. Use variable validation and constraints
echo "Creating variables with advanced validation..."
cat > validation-variables.tf << 'EOF'
variable "email_address" {
  description = "Administrator email address"
  type        = string
  validation {
    condition     = can(regex("^[@A-Za-z0-9-_]+\\.[@A-Za-z0-9-_]+@[A-Za-z0-9][A-Za-z0-9-_]+\\.[A-Za-z]{2,}$", var.email_address))
    error_message = "Email address must be valid."
  }
}

variable "password" {
  description = "Password for resources"
  type        = string
  sensitive   = true  # Marks value as sensitive in logs and UI
  validation {
    condition     = length(var.password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  validation {
    condition     = can(regex("^ssh-(rsa|dss|ecdsa|ed25519) [A-Za-z0-9+/]+[=]{0,2} ([^\\s]+)$", var.ssh_public_key))
    error_message = "SSH public key must be valid."
  }
}

variable "domain_name" {
  description = "Domain name for resources"
  type        = string
  validation {
    condition     = length(trimspace(var.domain_name)) > 0 && can(regex("^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])\\.)+[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be valid."
  }
}

# 3. Define output values
echo "Creating outputs.tf with various output types..."
cat > outputs.tf << 'EOF'
# Simple value outputs
output "environment" {
  description = "Environment selected"
  value       = var.environment
}

output "region" {
  description = "AWS region used"
  value       = var.aws_region
}

output "instance_count" {
  description = "Number of instances created"
  value       = var.web_instance_count
}

# Complex outputs
output "vpc_details" {
  description = "Details of the created VPC"
  value = {
    id          = aws_vpc.main.id
    cidr_block  = aws_vpc.main.cidr_block
    state       = aws_vpc.main.state
    tags        = aws_vpc.main.tags
  }
}

output "web_servers" {
  description = "Information about web servers"
  value = [
    for i in range(length(aws_instance.web)) : {
      id         = aws_instance.web[i].id
      instance_type = aws_instance.web[i].instance_type
      private_ip = aws_instance.web[i].private_ip
      public_ip  = aws_instance.web[i].public_ip
      tags       = aws_instance.web[i].tags
    }
  ]
}

output "load_balancer_info" {
  description = "Load balancer information"
  value = {
    dns_name    = aws_lb.web.dns_name
    arn         = aws_lb.web.arn
    security_groups = aws_lb.web.security_groups
    subnets     = aws_lb.web.subnets
  }
}

output "database_connection" {
  description = "Database connection information"
  value = {
    endpoint    = aws_db_instance.main.endpoint
    port        = aws_db_instance.main.port
    name        = aws_db_instance.main.name
    username    = var.database_config.username
    # Note: password is intentionally omitted for security
  }
  sensitive = true  # Mark output as sensitive
}

# Conditional outputs
output "database_endpoint" {
  description = "Database endpoint (only if database is created)"
  value       = var.create_db ? aws_db_instance.main.endpoint : null
}

# Output with dynamic keys
output "subnet_details" {
  description = "Details of all subnets"
  value = {
    for idx, subnet in aws_subnet.public : "subnet_${idx}" => {
      id            = subnet.id
      cidr_block    = subnet.cidr_block
      availability_zone = subnet.availability_zone
      map_public_ip = subnet.map_public_ip_on_launch
    }
  }
}

# 4. Use sensitive variables
echo "Demonstrating sensitive variable handling..."
cat > sensitive-example.tf << 'EOF'
# Sensitive variable example
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Using sensitive variable in resource
resource "aws_db_instance" "secure" {
  identifier  = "secure-db"
  engine      = "postgres"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  name        = "secureapp"
  username    = "admin"
  password    = var.db_password  # This value will be masked in logs/UI
  skip_final_snapshot = true

  tags = {
    Environment = var.environment
  }
}

# Even though it's used in resource, the value is still sensitive
# Terraform will mask it in:
# - terraform plan output
# - terraform apply output  
# - State file (when using terraform output)
# - Console output
# However, it IS stored in the state file (unless using external secrets management)

# 5. Practice terraform console and output inspection
echo "Practicing Terraform console and output inspection..."
terraform init
terraform fmt
terraform validate

# Console for testing expressions
echo "Testing expressions in terraform console:"
terraform console << 'EOF'
> var.environment
> upper(var.environment)
> length(var.allowed_cidr_blocks)
> var.allowed_cidr_blocks[0]
> "${var.environment}-${var.aws_region}"
> tomap({"a" = "1", "b" = "2"})
> length(tomap({"a" = "1", "b" = "2"}))
> [for s in var.allowed_cidr_blocks : upper(s)]
EOF

# Plan and inspect outputs
echo "Running terraform plan to see outputs..."
terraform plan -var="environment=dev" -var="web_instance_count=2" -out=tfplan

# Show planned outputs
echo "Planned outputs:"
terraform show -no-color tfplan | grep -A 2 -B 2 "outputs:" || echo "No outputs in plan (resources may be prevented)"

# Apply and get actual outputs (commented out to avoid actual resource creation)
# terraform apply tfplan
# terraform output
# terraform output -json
# terraform output environment
# terraform output -raw web_instance_ids

# Cleanup
cd ..
rm -rf terraform-basics
```
</details>

<details>
<summary>Exercise 4 Solutions: State Management and Data Sources</summary>

```bash
# 1. Understand Terraform state file
echo "Understanding Terraform state file..."
mkdir -p terraform-state
cd terraform-state

cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "random" {
  # No configuration needed
}

# Simple resources for state demonstration
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "state-demo-web"
  }
}

resource "random_pet" "server_name" {
  length = 2
}

resource "aws_s3_bucket" "logs" {
  bucket = "state-demo-logs-${random_pet.server_name.id}"
  acl    = "private"

  tags = {
    Environment = "demo"
  }
}
EOF

terraform init
terraform apply -auto-approve

echo "Examining Terraform state file..."
echo "State file location: terraform.tfstate"
echo ""
echo "Human-readable state:"
terraform show
echo ""
echo "JSON format state:"
terraform show -json | jq '.'
echo ""
echo "State file contents (raw):"
cat terraform.tfstate | jq '.'
echo ""
echo "State version:"
terraform state list | head -1
echo ""
echo "Resources in state:"
terraform state list
echo ""
echo "Detailed resource information:"
terraform state show aws_instance.web
terraform state show random_pet.server_name
terraform state show aws_s3_bucket.logs

# 2. Practice state commands (list, show, replace)
echo "Practicing Terraform state commands..."
echo ""
echo "=== State List Commands ==="
echo "terraform state list                    # List all resources"
echo "terraform state list 'aws_instance.*'   # List resources matching pattern"
echo "terraform state list -state=terraform.tfstate.backup  # List from backup"

echo ""
echo "=== State Show Commands ==="
echo "terraform state show aws_instance.web   # Show specific resource"
echo "terraform state show 'random_pet.*'     # Show resources matching pattern"

echo ""
echo "=== State Replace Commands ==="
echo "# Replace provider configuration in state"
echo "# terraform state replace-provider 'hashicorp/aws' 'hashicorp/aws'"
echo ""
echo "# Replace module in state"
echo "# terraform state replace-module MODULE_ADDRESS NEW_MODULE_SOURCE"

echo ""
echo "=== State Move Commands ==="
echo "# Move resource to different state or address"
echo "# terraform state move aws_instance.web aws_instance.web[0]"
echo "# terraform state move -state-out=moved.tfstate aws_instance.web "

echo ""
echo "=== State Remove Commands ==="
echo "# Remove resource from state (but not destroy it)"
echo "# terraform state rm aws_instance.web"
echo "# terraform state rm 'aws_instance.*'"

echo ""
echo "=== State Pull/Push Commands ==="
echo "# For remote state operations"
echo "# terraform state pull > local-state.tfstate"
echo "# terraform state push local-state.tfstate"

# 3. Use data sources to query existing resources
echo "Using data sources to query existing resources..."
cat > data-sources.tf << 'EOF'
# Get information about existing AWS resources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {
  # Gets the current region from provider configuration
}

data "aws_caller_identity" "current" {
  # Gets information about the AWS account/user making the request
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "allow_http" {
  name   = "allow_http"
  vpc_id = data.aws_vpc.default.id
}

# Use data sources in resources
resource "aws_instance" "from_data" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_security_group_ids = [data.aws_security_group.allow_http.id]

  tags = {
    Name = "from-data-source"
    Source = "data_sources_demo"
  }
}

# Output data source information
output "availability_zones" {
  description = "Available AZs in current region"
  value       = data.aws_availability_zones.available.names
}

output "current_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "latest_amazon_linux_ami" {
  description = "Most recent Amazon Linux AMI"
  value       = data.aws_ami.amazon_linux.id
}

output "default_vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}

output "subnet_count" {
  description = "Number of subnets in default VPC"
  value       = length(data.aws_subnet_ids.all.ids)
}
EOF

terraform apply -auto-approve

echo "Data source outputs:"
terraform output availability_zones
terraform output current_region
terraform output account_id
terraform output latest_amazon_linux_ami
terraform output default_vpc_id
terraform output subnet_count

# 4. Implement remote state basics
echo "Setting up remote state with S3 backend..."
cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    # Optional: Enable state locking with DynamoDB
    # dynamodb_table = "terraform-locks"
    # Optional: Use a specific profile
    # profile        = "terraform"
  }
}
EOF

echo "# To use this backend:"
echo "1. Create S3 bucket: aws s3api create-bucket --bucket my-terraform-state-bucket --region us-east-1"
echo "2. Enable versioning: aws s3api put-bucket-versioning --bucket my-terraform-state-bucket --versioning-configuration Status=Enabled"
echo "3. Create DynamoDB table for locking (optional):"
echo "   aws dynamodb create-table \\"
echo "     --table-name terraform-locks \\"
echo "     --attribute-definitions AttributeName=LockID,AttributeType=S \\"
echo "     --key-schema AttributeName=LockID,KeyType=HASH \\"
echo "     --billing-mode PAY_PER_REQUEST"
echo ""
echo "4. Initialize with backend: terraform init"
echo "5. Terraform will automatically lock/unlock state during operations"

# 5. Practice state locking concepts
echo "Understanding state locking..."
echo ""
echo "# State locking prevents concurrent operations that could corrupt state"
echo ""
echo "# Backends that support locking:"
echo "- Amazon S3 with DynamoDB table"
echo "- HashiCorp Terraform Cloud/Enterprise"
echo "- Azure Blob Storage with Azure Storage locks"
echo "- Google Cloud Storage with Firestore"
echo "- Consul"
echo "- etcd"
echo "- Kubernetes (via ConfigMaps)"
echo "- Oracle Cloud Infrastructure Object Storage"
echo ""
echo "# How locking works:"
echo "1. When terraform init runs with a locking backend, it acquires a lock"
echo "2. The lock prevents other terraform operations from running simultaneously"
echo "3. When the operation completes, the lock is released"
echo "4. If a operation fails while holding a lock, the lock may need to be force-released"
echo ""
echo "# Manual lock handling (use with caution!)"
echo "# To force release a lock:"
echo "# terraform force-unlock LOCK_ID"
echo ""
echo "# To view current lock:"
echo "# terraform force-unlock -lock-id=LOCK_ID  # Shows lock info without releasing"
echo ""
echo "# Best practices:"
echo "- Always use locking for shared state"
echo "- Monitor lock duration in long-running operations"
echo "- Set up alerts for stuck locks"
echo "- Document lock procedures for team members"

# Cleanup
cd ..
rm -rf terraform-state
```
</details>

<details>
<summary>Exercise 5 Solutions: Modules and Reusability</summary>

```bash
# 1. Create reusable Terraform modules
echo "Creating reusable Terraform module for AWS web server..."
mkdir -p modules
mkdir -p modules/web-server
mkdir -p examples
mkdir -p examples/simple
mkdir -p examples/production

# Create module variables
cat > modules/web-server/variables.tf << 'EOF'
variable "instance_type" {
  description = "EC2 instance type for web server"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID to use for web server"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for web server placement"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where web server will be deployed"
  type        = string
}

variable "server_count" {
  description = "Number of web server instances to create"
  type        = number
  default     = 1
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access web server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to web server resources"
  type        = map(string)
  default     = {}
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Path for load balancer health check"
  type        = string
  default     = "/"
}

# 2. Create module resources
cat > modules/web-server/main.tf << 'EOF'
# Create security group for web servers
resource "aws_security_group" "web" {
  name        = "${var.tags.Name}-web-sg"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-web-sg"
  })
}

# Create web server instances
resource "aws_instance" "web" {
  count             = var.server_count
  ami               = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = element(var.subnet_ids, count.index % length(var.subnet_ids))
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-web-${count.index}"
  })

  lifecycle {
    create_before_destroy = var.server_count > 1
  }
}

# Optional: Create load balancer for multiple instances
resource "aws_lb" "web" {
  count             = var.server_count > 1 ? 1 : 0
  name              = "${var.tags.Name}-alb"
  internal          = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.web.id]
  subnets           = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-alb"
  }
)

resource "aws_lb_target_group" "web" {
  count             = var.server_count > 1 ? 1 : 0
  name              = "${var.tags.Name}-tg"
  port              = 80
  protocol          = "HTTP"
  vpc_id            = var.vpc_id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-tg"
  }
)

resource "aws_lb_listener" "web" {
  count             = var.server_count > 1 ? 1 : 0
  load_balancer_arn = element(aws_lb.web.*.arn, 0)
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = element(aws_lb_target_group.web.*.arn, 0)
  }
}

# Attach instances to target group
resource "aws_lb_target_group_attachment" "web" {
  count             = var.server_count > 1 ? length(var.instance_type) * var.server_count : 0
  target_group_arn  = element(aws_lb_target_group.web.*.arn, 0)
  target_id         = element(aws_instance.web.*.id, count.index)
  target_port       = 80
}

# 3. Create module outputs
cat > modules/web-server/outputs.tf << 'EOF'
output "instance_ids" {
  description = "IDs of web server instances"
  value       = aws_instance.web[*].id
}

output "instance_private_ips" {
  description = "Private IPs of web server instances"
  value       = aws_instance.web[*].private_ip
}

output "instance_public_ips" {
  description = "Public IPs of web server instances"
  value       = aws_instance.web[*].public_ip
}

output "security_group_id" {
  description = "ID of web server security group"
  value       = aws_security_group.web.id
}

output "load_balancer_dns_name" {
  description = "DNS name of load balancer (if created)"
  value       = var.server_count > 1 ? aws_lb.web[0].dns_name : null
}

output "target_group_arn" {
  description = "ARN of target group (if created)"
  value       = var.server_count > 1 ? aws_lb_target_group.web[0].arn : null
}

output "web_server_tags" {
  description = "Tags applied to web server instances"
  value       = aws_instance.web[*].tags
}
EOF

# 4. Create module documentation
cat > modules/web-server/README.md << 'EOF'
# Web Server Module

This module creates AWS EC2 instances configured as web servers with optional load balancing.

## Usage

```hcl
module "web_server" {
  source = "./modules/web-server"

  instance_type = "t3.micro"
  ami_id        = data.aws_ami.amazon_linux.id
  subnet_ids    = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  vpc_id        = aws_vpc.main.id
  server_count  = 3
  tags = {
    Environment = "prod"
    Team        = "platform"
    Project     = "web-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami_id | AMI ID to use for web server | string | - | yes |
| instance_type | EC2 instance type | string | `t2.micro` | no |
| subnet_ids | List of subnet IDs | list(string) | - | yes |
| vpc_id | VPC ID | string | - | yes |
| server_count | Number of instances | number | `1` | no |
| allowed_cidr_blocks | Allowed CIDR blocks | list(string) | `[\"0.0.0.0/0\"]` | no |
| tags | Resource tags | map(string) | `{}` | no |
| enable_detailed_monitoring | Enable detailed monitoring | bool | `false` | no |
| health_check_path | Health check path | string | `"/"` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_ids | IDs of web server instances |
| instance_private_ips | Private IPs of web server instances |
| instance_public_ips | Public IPs of web server instances |
| security_group_id | ID of web server security group |
| load_balancer_dns_name | DNS name of load balancer (if server_count > 1) |
| target_group_arn | ARN of target group (if server_count > 1) |
| web_server_tags | Tags applied to web server instances |
EOF

# 5. Create examples using the module
echo "Creating simple example using the module..."
cat > examples/simple/main.tf << 'EOF'
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create VPC and subnets for the example
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "example-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "example-igw"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "example-private-${count.index}"
  }
}

# Use the web server module
module "web_server" {
  source = "../modules/web-server"

  instance_type = "t3.micro"
  ami_id        = data.aws_ami.amazon_linux.id
  subnet_ids    = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  vpc_id        = aws_vpc.main.id
  server_count  = 2
  tags = {
    Environment = "dev"
    Team        = "learning"
    Project     = "web-server-module"
  }
}

# Outputs from the example
output "web_server_instance_ids" {
  value = module.web_server.instance_ids
}

output "web_server_public_ips" {
  value = module.web_server.instance_public_ips
}
EOF

echo "Creating production example with variations..."
cat > examples/production/main.tf << 'EOF'
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Input variables for production example
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create production VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
    Environment = var.environment
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-private-${count.index}"
    Environment = var.environment
  }
}

# Use the web server module with production settings
module "web_server" {
  source = "../../modules/web-server"

  instance_type = "t3.medium"
  ami_id        = data.aws_ami.amazon_linux.id
  subnet_ids    = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  vpc_id        = aws_vpc.main.id
  server_count  = 3
  allowed_cidr_blocks = ["10.0.0.0/16", "192.168.0.0/16"]  # Restrict access
  tags = {
    Environment = var.environment
    Team        = "platform"
    Project     = "production-web-app"
    Owner       = "devops-team"
  }
  enable_detailed_monitoring = true
  health_check_path = "/health"
}

# Outputs
output "web_server_count" {
  value = length(module.web_server.instance_ids)
}

output "web_server_public_ips" {
  value = module.web_server.instance_public_ips
}

output "security_group_id" {
  value = module.web_server.security_group_id
}
EOF

# 6. Demonstrate module sources
echo "Demonstrating different module sources..."
cat > module-sources-examples.tf << 'EOF'
# Local module source
module "local_web" {
  source = "./modules/web-server"
  # ... configuration
}

# Registry module source
module "registry_web" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"
  # ... configuration
}

# Git module source
module "git_web" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git"
  # ... configuration
}

# GitHub module source
module "github_web" {
  source = "github.com/terraform-aws-modules/terraform-aws-ec2-instance"
  # ... configuration
}

# Mercurial module source
module "hg_web" {
  source = "hg::https://example.com/hg/module"
  # ... configuration
}

# HTTP archive module source
module "http_web" {
  source = "https://example.com/module.tar.gz"
  # ... configuration
}

# S3 module source
module "s3_web" {
  source = "s3://my-bucket/module.tar.gz"
  # ... configuration
}
EOF

# 7. Practice module versioning
echo "Demonstrating module versioning strategies..."
echo ""
echo "# Version constraints in module source:"
echo ""
echo "# Exact version"
echo 'source = "terraform-aws-modules/ec2-instance/aws"'
echo 'version = "3.14.0"'
echo ""
echo "# Version range"
echo 'source = "terraform-aws-modules/ec2-instance/aws"'
echo 'version = "~> 3.0"  # >= 3.0, < 4.0'
echo ''
echo 'source = "terraform-aws-modules/ec2-instance/aws"'
echo 'version = ">= 3.5.0, < 4.0.0"'
echo ""
echo "# Latest version (not recommended for production)"
echo 'source = "terraform-aws-modules/ec2-instance/aws"'
echo 'version = ">= 0.0.0"  # Any version'
echo ""
echo "# Prerelease versions"
echo 'source = "terraform-aws-modules/ec2-instance/aws"'
echo 'version = ">= 4.0.0-beta1, < 5.0.0"'
echo ""
echo "# Version from environment variable (for CI/CD)"
echo 'variable "ec2_module_version" {'
echo '  type    = string'
echo '  default = "~> 4.0"'
echo '}'
echo ''
echo 'module "ec2_instance" {'
echo '  source  = "terraform-aws-modules/ec2-instance/aws"'
echo '  version = var.ec2_module_version'
echo '  # ... configuration'
echo '}'
echo ""
echo "# Locking versions with .terraform.lock.hcl"
echo "# Always commit the lock file to version control"
echo "# terraform providers lock -upgrade  # To update to latest allowed versions"

# 8. Test the modules
echo "Testing module functionality..."
cd examples/simple
terraform init
terraform get  # Install modules
terraform validate
terraform plan -var="aws_region=us-east-1"

# Show what the module would create
echo "Module resources that would be created:"
terraform plan -var="aws_region=us-east-1" -no-color | grep -E "(+ create|# (aws_|module\.))"

cd ../..
# Cleanup
rm -rf modules examples
```
</details>