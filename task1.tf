provider "aws" {
  region     = "ap-south-1"
  profile    = "chahatnew"
}

#creating security group: 
resource "aws_security_group" "secgroup" {
  name        = "newgroup"
  description = "Allow http inbound traffic"
  

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "allow_http"
  }
}


#creating a key pair

resource "tls_private_key" "task1-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "task1-key" {
  key_name   = "task1key"
  public_key = tls_private_key.task1-key.public_key_openssh
}

# saving key to local file
resource "local_file" "task1-key" {
    content  = tls_private_key.task1-key.private_key_pem
    filename = "/root/terraform/task1key.pem"
}


#launch an ec2 instance:
resource "aws_instance" "taskinstance"{

  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "task1key"
  availability_zone = "ap-south-1a"
  security_groups = ["newgroup"]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.task1-key.private_key_pem
    host     = aws_instance.taskinstance.public_ip
  } 
 provisioner "remote-exec" {
    inline = [
         "sudo yum update -y",
         "sudo yum install httpd git -y",
         "sudo systemctl start httpd",
         "sudo systemctl enable httpd", 
               ]
 }  
  tags = {
    Name = "task1 os"
  }
}

#creating EBS volume:
resource "aws_ebs_volume" "taskebs" {
  availability_zone = "ap-south-1a"
  size              = 1

  tags = {
    Name = "HelloWorld"
  }
}

#attaching EBS volume to instance
resource "aws_volume_attachment" "ebsatt" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.taskebs.id}"
  instance_id = "${aws_instance.taskinstance.id}"
  force_detach = true
}

output "myos_ip" {
  value = aws_instance.taskinstance.public_ip
}

resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.taskinstance.public_ip} > publicip.txt"
  	}
}



resource "null_resource" "nullremote1"  {

depends_on = [
    aws_volume_attachment.ebsatt,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.task1-key.private_key_pem
    host     = aws_instance.taskinstance.public_ip
  }

 provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/chahatparnami/task1-repo.git /var/www/html",
     ]
 }
}


#creating S3 bucket:
resource "aws_s3_bucket" "meharsagar" {

depends_on = [aws_instance.taskinstance]

  bucket = "meharsagar"
  acl    = "public-read"
  
  tags = {
    Name        = "taskbckt"
    Environment = "Dev"
  }

provisioner "local-exec" {
 command = "git clone https://github.com/chahatparnami/task1-repo task1 "
  }
provisioner "local-exec" {
 when = destroy
 command = "echo Y | rmdir /s image"
  }
}

 
resource "aws_s3_bucket_public_access_block" "publics3" {
  bucket = "meharsagar"
}

output "bucket_id" {
  value = aws_s3_bucket.meharsagar.id
}


#adding object in S3 bucket:
resource "aws_s3_bucket_object" "objectimg" {
 depends_on = [aws_s3_bucket.meharsagar,]
  bucket = "meharsagar"
  key    = "terraform.jpg"
  acl    = "public-read"
  source = "task1/terraform.jpg"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}

output "cloudfront-origin" {
  value = "aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path"
}


#creating CloudFront distribution:
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.meharsagar.bucket_domain_name
    origin_id   = "${local.s3_origin_id}"
  
  s3_origin_config { 
    origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}" 
  } 
  }

  
  enabled             = true
  is_ipv6_enabled     = true

  default_cache_behavior  {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }
 
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400 
  }
  

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
 
  
  
  }
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}


resource "null_resource" "cloudfrontdns" {
  
depends_on = [aws_cloudfront_origin_access_identity.origin_access_identity]

     provisioner "local-exec" {
       command = "echo ${aws_cloudfront_distribution.s3_distribution.domain_name} >cloudfrontdomainfile.txt"
       
     }
}


#uploading files to S3
data "aws_iam_policy_document" "s3_bucket_policy" { 
  statement { 
    actions = ["s3:GetObject"] 
    resources = ["${aws_s3_bucket.meharsagar.arn}/*"] 
    
    principals { 
      type = "AWS" 
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"] 
    } 
  }   
  
  statement { 
    actions = ["s3:ListBucket"] 
    resources = ["${aws_s3_bucket.meharsagar.arn}"] 

    principals { 
      type = "AWS" 
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]    
    } 

  }
} 


#creating bucket policy
resource "aws_s3_bucket_policy" "s3BucketPolicy" { 
  bucket = "${aws_s3_bucket.meharsagar.id}" 
  policy = "${data.aws_iam_policy_document.s3_bucket_policy.json}"
} 


#launching site
resource "null_resource" "launch_site" {
depends_on =[ aws_cloudfront_distribution.s3_distribution,aws_instance.taskinstance,aws_volume_attachment.ebsatt, ]
  connection {
    type = "ssh"
    user = "ec2-user"
    host = aws_instance.taskinstance.public_ip
    port = 22
    private_key = tls_private_key.task1-key.private_key_pem
  }

 provisioner "remote-exec" {
   inline = [
    "sudo su <<EOF",
    "echo \"<img src = 'http://${aws_cloudfront_distribution.s3_distribution.domain_name}/${aws_s3_bucket_object.objectimg.key}' width='100%' height='100%'>\" >> /var/www/html/index.html",
                  "EOF",
                  "sudo systemctl restart httpd"
     ]
 }
 provisioner "local-exec" {
   command = "start chrome ${aws_instance.taskinstance.public_ip}"
 }
}

