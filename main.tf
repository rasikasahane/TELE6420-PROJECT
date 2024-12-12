provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
data "aws_caller_identity" "current" {}

# VPC Configuration
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

# Configuration for Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}



# Public Subnets Configuration


# Public Subnet 1 in Availability Zone 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-subnet-1"
  }
}

# Public Subnet 2 in Availability Zone 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-subnet-2"
  }
}

# Public Subnet 3 in Availability Zone 3
resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[2]
  availability_zone       = var.availability_zones[2]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-subnet-3"
  }
}


# Private Subnets Configuration


# Private Subnet 1 in Availability Zone 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "${var.vpc_name}-private-subnet-1"
  }
}

# Private Subnet 2 in Availability Zone 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = var.availability_zones[1]
  tags = {
    Name = "${var.vpc_name}-private-subnet-2"
  }
}

# Private Subnet 3 in Availability Zone 3
resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[2]
  availability_zone = var.availability_zones[2]
  tags = {
    Name = "${var.vpc_name}-private-subnet-3"
  }
}

# Route Table Configuration

# Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.vpc_name}-public-route-table"
  }
}

# NAT Public route to Internet gateway
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Associate Public Subnets with Public Route Table#
resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_3" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public_route_table.id
}

# Private Route Table##
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.vpc_name}-private-route-table"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_route_table_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_3" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_route_table.id
}


# Application Security Group
resource "aws_security_group" "app_security_group" {
  vpc_id = aws_vpc.main_vpc.id

  name        = "app-security-group"
  description = "Security group for EC2 instances hosting web applications"


  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_security_group.id]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-security-group"
  }
  depends_on = [aws_security_group.lb_security_group]
}

##SSH KEY CONFIG
resource "tls_private_key" "web_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

#Upload the public key to AWS as an EC2 key pair
resource "aws_key_pair" "web_key_pair" {
  key_name   = "web-app-key" # Name of the key pair
  public_key = tls_private_key.web_ssh_key.public_key_openssh
}

#Save the private key locally
resource "local_file" "ssh_private_key" {
  filename        = "${path.module}/web-app-key.pem"
  content         = tls_private_key.web_ssh_key.private_key_pem
  file_permission = "0400"
}

# Database Security Group
resource "aws_security_group" "db_security_group" {
  vpc_id = aws_vpc.main_vpc.id

  name        = "db-security-group"
  description = "Security group for PostgreSQL database access"

  # Ingress rule to allow PostgreSQL traffic 
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_security_group.id]
  }

  # Egress rule to allow outbound traffic from the DB
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-security-group"
  }
}

# RDS Subnet Group (Private Subnet)
resource "aws_db_subnet_group" "tele6420_subnet_group" {
  name = "tele6420-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id
  ]

  tags = {
    Name = "tele6420-subnet-group"
  }
}

# RDS Parameter Group for PostgreSQL 16
resource "aws_db_parameter_group" "db_parameter_group" {
  name        = "tele6420-postgres16-parameter-group"
  family      = "postgres16"
  description = "Custom parameter group for PostgreSQL 16"

  tags = {
    Name = "tele6420-postgres16-parameter-group"
  }
}

# RDS Instance
resource "aws_db_instance" "tele6420_db" {
  identifier             = "tele6420"
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  parameter_group_name   = aws_db_parameter_group.db_parameter_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false


  db_subnet_group_name = aws_db_subnet_group.tele6420_subnet_group.name

  tags = {
    Name = "tele6420-postgres16-db-instance"
  }
}

output "db_host" {
  value       = aws_db_instance.tele6420_db.endpoint
  description = "The endpoint of the RDS instance"
}



#IAM Policy to allow access to Cloudwatch and S3
resource "aws_iam_policy" "ec2_policy" {
  name        = "cloudwatch-s3-policy"
  description = "Policy for EC2 to send logs to CloudWatch and access S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }

    ]
  })

  depends_on = [aws_db_instance.tele6420_db]
}
#IAM ROLE for S3 and Cloudwatch
resource "aws_iam_role" "ec2_role" {
  name = "cloudwatch-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  depends_on = [aws_iam_policy.ec2_policy]
}
#Attaching the policy
resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn

  depends_on = [aws_iam_role.ec2_role]
}
#Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name       = "ec2-s3-access-profile"
  role       = aws_iam_role.ec2_role.name
  depends_on = [aws_iam_role_policy_attachment.attach_ec2_policy]
}

#DNS record
resource "aws_route53_record" "a_record_dev" {
  zone_id = var.route53_zone_id
  name    = var.record_name
  type    = "A"
  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
  depends_on = [aws_lb.app_lb]
}

# Load Balancer Security Group
resource "aws_security_group" "lb_security_group" {
  vpc_id = aws_vpc.main_vpc.id

  name        = "load-balancer-security-group"
  description = "Security group for Load Balancer to access the web application"

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }



  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "load-balancer-security-group"
  }
}


# Launch Template for Auto Scaling Group
resource "aws_launch_template" "tele6420_asg" {
  name_prefix   = "tele6420_asg"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.web_key_pair.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_security_group.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 10
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Wait for network to be ready
    sleep 30

    # Enable password authentication for Serial Console access
    echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd

    DB_PASSWORD=${var.db_password}
    DB_USERNAME=${var.db_username}
    # Set a password for the default user
    echo "ubuntu:ubuntu" | sudo chpasswd
    #stop application
    sudo systemctl stop app.service

    # Update the .env file with correct endpoint
    DB_HOST=$(echo "${aws_db_instance.tele6420_db.endpoint}" | cut -d ':' -f 1)
    sudo sed -i "s/^DB_HOST=.*/DB_HOST='"$DB_HOST"'/" /home/app/.env
    sudo sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" /home/app/.env
    sudo sed -i "s/^DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" /home/app/.env
    cat /home/app/.env

    # Start the application
    sudo systemctl daemon-reload
    sudo systemctl enable app.service
    sudo systemctl start app.service
    
  EOF
  )
  depends_on = [
    aws_db_instance.tele6420_db,
    aws_iam_instance_profile.ec2_profile,
    aws_security_group.app_security_group
  ]
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_app_asg" {
  desired_capacity    = 3
  max_size            = 5
  min_size            = 3
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.public_subnet_3.id]
  launch_template {
    id      = aws_launch_template.tele6420_asg.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "web-app-instance"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  depends_on                = [aws_lb_target_group.app_tg]
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high_cpu_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_asg.name
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = "low_cpu_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 4.5
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_asg.name
  }
}
# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "${var.vpc_name}-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_security_group.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.public_subnet_3.id]

  tags = {
    Name = "${var.vpc_name}-app-lb"
  }
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
  health_check {
    path                = "/students"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener for Load Balancer
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}