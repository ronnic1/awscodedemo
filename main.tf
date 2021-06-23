#Let's start on our terraform main.tf file.
#Amazon Virtual Private Cloud (Amazon VPC) is a service that lets you launch AWS resources in a logically isolated virtual network that you define. You have complete control over your virtual networking environment, including selection of your own IP address range, creation of subnets, and configuration of route tables and network gateways.

#Start with the provider block. We'll use us-east-1 as the region for this example.

provider "aws" {
region = "us-east-1"
}

#Then add the vpc resource block and specify the cidr 10.0.0.0/16

resource "aws_vpc" "main" {
cidr_block = "10.0.0.0/16"

tags = {
Name = "Main VPC"
}
}

#	2. A subnet (public)

#Subnets make networks more efficient. Through subnetting, network traffic can travel a shorter distance without passing through unnecessary routers to reach its destination. For more on subnets, follow this link.
# Create the resource blocks for the subnet specifying the cidr. The vpc_id will link back to the aws_vpc we created in the previous step.

}
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

#	3. An autoscaling group with Amazon Linux 2 instance (t3.nano) with a min of 2 instances and max of 3.

#Create a aws launch configuration resource and the autoscaling group.
#A launch configuration is an instance configuration template that an Auto Scaling group uses to launch EC2 instances. When you create a launch configuration, you specify information for the instances. Include the ID of the Amazon Machine Image (AMI), the instance type, a key pair, one or more security groups, and a block device mapping. FYI you can use a launch configuration or a launch template to create an auto scaling group. The image id and instance type will reference the variables in the var.tf file created at the beginning of the lab.


resource "aws_launch_configuration" "launch_configuration" {
name_prefix = "demo"
image_id = var.ami
instance_type = var.instance_type
}
resource "aws_autoscaling_group" "aws_asg_config" {
name = "demo_autoscaling_group"
min_size = 2
max_size = 3
health_check_type = "EC2"
launch_configuration = aws_launch_configuration.launch_configuration.name
availability_zones = [ "us-east-1a", "us-east-1b" ]
lifecycle {
create_before_destroy = true
}
}

#	4. Create a bucket to store your terraform state 

#For your bucket name it is important to remember these rules to avoid and InvalidBucketName error:
#		• The bucket name can be between 3 and 63 characters long, and can contain only lower-case characters, numbers, periods, and dashes.
#		• Each label in the bucket name must start with a lowercase letter or number.
#		• The bucket name cannot contain underscores, end with a dash, have consecutive periods, or use dashes adjacent to periods.
#		• The bucket name cannot be formatted as an IP address (198.51.100.24).
#S3 backend stores the state file as a given key in a given bucket on Amazon S3. This backend also supports state locking and consistency checking via Dynamo DB, which can be enabled by setting the dynamodb_table field to an existing DynamoDB table name.

resource "aws_s3_bucket" "s3bucket" {
bucket = "cicdawsdemo"
versioning {
enabled = true
}
lifecycle {
prevent_destroy = true
}
}
resource "aws_dynamodb_table" "terraform_state_lock" {
name = "app-state"
read_capacity = 1
write_capacity = 1
hash_key = "LockID"
attribute {
name = "LockID"
type = "S"
}
}
