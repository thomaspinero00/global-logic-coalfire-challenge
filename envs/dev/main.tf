
# ================================================================
# Networking: VPC, Subnets, NAT Gateways, Routes

module "vpc" {
  source                    = "github.com/Coalfire-CF/terraform-aws-vpc-nfw"
  cidr                      = "10.1.0.0/16"
  azs                       = ["us-east-1a", "us-east-1b"]
  public_subnets            = ["10.1.0.0/24", "10.1.1.0/24"]
  private_subnets           = ["10.1.2.0/24", "10.1.3.0/24"]
  flow_log_destination_type = "cloud-watch-logs"
  private_subnet_tags = {
    "0" = "private-subnet-az1"
    "1" = "private-subnet-az2"
  }
  public_subnet_tags = {
    "0" = "public-subnet-az1"
    "1" = "public-subnet-az2"
  }
}

resource "aws_eip" "nat_az1" {
  tags = {
    Name = "global-logic-nat-eip-az1"
  }
}

resource "aws_nat_gateway" "nat_az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = module.vpc.public_subnets["-public-us-east-1a"] # First public subnet (us-east-1a)
  tags = {
    Name = "global-logic-nat-az1"
  }
}

resource "aws_eip" "nat_az2" {
  tags = {
    Name = "global-logic-nat-eip-az2"
  }
}

resource "aws_nat_gateway" "nat_az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = module.vpc.public_subnets["-public-us-east-1b"]
  tags = {
    Name = "global-logic-nat-az2"
  }
}

resource "aws_route" "private_nat_az1" {
  route_table_id         = module.vpc.private_route_table_ids[0] # First private AZ
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az1.id
}

resource "aws_route" "private_nat_az2" {
  route_table_id         = module.vpc.private_route_table_ids[1] # Second private AZ
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az2.id
}
# ================================================================


# ================================================================
# Security Groups
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP inbound from the world"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "asg" {
  name        = "asg-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Allow SSH from my IP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Replace with your real IP
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# ================================================================

# ================================================================
# S3 Buckets and Lifecycle Policies

resource "aws_s3_bucket" "images" {
  bucket = "global-logic-images"
}

resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "MoveMemesToGlacier"
    status = "Enabled"

    filter {
      prefix = "memes/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}


resource "aws_s3_bucket" "logs" {
  bucket = "global-logic-logs"
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "ActiveToGlacier"
    status = "Enabled"

    filter {
      prefix = "active/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "InactiveDelete"
    status = "Enabled"

    filter {
      prefix = "inactive/"
    }

    expiration {
      days = 90
    }
  }
}

# ================================================================

# ================================================================
# IAM Roles, Policies and Instance Profiles

resource "aws_iam_role" "ec2_logs" {
  name               = "ec2-logs-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy" "ec2_write_logs" {
  name   = "ec2-write-logs"
  role   = aws_iam_role.ec2_logs.id
  policy = data.aws_iam_policy_document.write_logs.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "write_logs" {
  statement {
    actions = ["s3:PutObject", "s3:GetBucketLocation", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]
  }
}

resource "aws_iam_role" "asg" {
  name               = "asg-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy" "asg_read_images" {
  name   = "asg-read-images"
  role   = aws_iam_role.asg.id
  policy = data.aws_iam_policy_document.read_images.json
}

data "aws_iam_policy_document" "read_images" {
  statement {
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.images.arn,
      "${aws_s3_bucket.images.arn}/*"
    ]
  }
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_logs.name
}
# ================================================================



# ================================================================
# Application Load Balancer (ALB) and Target Group


module "alb" {
  source                     = "terraform-aws-modules/alb/aws"
  version                    = "9.17.0"
  name                       = "global-logic-alb"
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  enable_deletion_protection = false
  subnets = [
    module.vpc.public_subnets["-public-us-east-1a"],
    module.vpc.public_subnets["-public-us-east-1b"]
  ]
  security_groups = [aws_security_group.alb.id]



}

resource "aws_lb_target_group" "asg_tg" {
  name_prefix = "asgtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"
  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
    port     = "80"
  }
}



resource "aws_lb_listener" "main" {
  load_balancer_arn = module.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_tg.arn


  }
}
# ================================================================


# ================================================================
# AMI Data Source
data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat official

  filter {
    name   = "name"
    values = ["RHEL-8.?*_HVM-*-x86_64-*"]
  }
}
# ================================================================




# ================================================================
# Autoscaling Group (ASG)

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.5.0"

  name             = "global-logic-asg"
  min_size         = 2
  max_size         = 6
  desired_capacity = 2

  vpc_zone_identifier = [module.vpc.private_subnets["-private-subnet-az1-us-east-1a"], module.vpc.private_subnets["-private-subnet-az2-us-east-1b"]]
  health_check_type   = "EC2"

  target_group_arns = [aws_lb_target_group.asg_tg.arn]


  image_id                 = data.aws_ami.rhel.id # RedHat Linux AMI
  instance_type            = "t2.micro"
  user_data                = filebase64("../../scripts/user_data_apache.sh")
  iam_instance_profile_arn = aws_iam_instance_profile.ec2_profile.arn
  key_name                 = aws_key_pair.ec2_key.key_name
  security_groups          = [aws_security_group.ec2.id]

  tags = {
    Name = "asg-instance"
  }
}
# ================================================================


# ================================================================
# SSH Key Pair

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "global-logic-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "ec2_key_pem" {
  content              = tls_private_key.ec2_key.private_key_pem
  filename             = "${path.module}/global-logic-key.pem"
  file_permission      = "0400"
  directory_permission = "0700"
}

# ================================================================


# ================================================================
# Standalone EC2 Instance
module "standalone_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name                   = "global-logic-ec2"
  ami                    = data.aws_ami.rhel.id # RedHat Linux AMI
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets["-public-us-east-1a"]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file("../../scripts/user_data_apache.sh")
  key_name               = aws_key_pair.ec2_key.key_name
  root_block_device = [
    {
      volume_size = 20
      volume_type = "gp3"
    }
  ]
  tags = {
    Name = "standalone-ec2"
  }
}
# ================================================================
