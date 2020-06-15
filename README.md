This lockdown gave us all an excellent opportunity to enhance our skills so i recently started learning about hybrid multi-computing where this is the first small project created by the information and knowledge that i have gathered.

This is the first task which is to create an entire architecture using AWS services and automating it using Terraform.

#What is AWS?
Amazon Web Services is a subsidiary of Amazon that provides on-demand cloud computing platforms and APIs to individuals, companies, and governments, on a metered pay-as-you-go basis.

#What is Terraform?
Terraform is an open-source infrastructure as code software tool created by HashiCorp. It enables users to define and provision a data centre infrastructure using a high-level configuration language known as Hashicorp Configuration Language, or optionally JSON.

Terraform file extension is “file_name.tf".

#Problem Statement:

1. Create the private key and security group which allows the port 80.
2. Launch Amazon AWS EC2 instance.
3. In this EC2 instance use the key and security group which we have created in step 1 to log-in remote or local.
4. Launch one Volume (EBS) and mount that volume into /var/www/html
5. The developer has uploaded the code into GitHub repo also the repo has some images.
6. Copy the GitHub repo code into /var/www/html
7. Create an S3 bucket, and copy/deploy the images from GitHub repo into the S3 bucket and change the permission to public readable.
8. Create a Cloudfront using S3 bucket(which contains images) and use the Cloudfront URL to update in code in /var/www/html

#PREQUISITES:

-Configure AWS.
-Configure the AWS profile.
-Download Terraform

#LOGIN TO AWS ACCOUNT THROUGH COMMAND PROMPT
 -Command:-aws configure — profile user_name

#STEP 1: declaring provider used here
#STEP 2: creating security group
A security group acts as a virtual firewall for your instance to control inbound and outbound traffic.So, we create a security group which allows a HTTP and SSH inbound traffic from all sources and similarly we create a outbound traffic rules to connect to all the IP's .
#STEP 3:create key pair
Amazon EC2 uses public key cryptography to encrypt and decrypt login information. Public key cryptography uses a public key to encrypt a piece of data, and then the recipient uses the private key to decrypt the data. The public and private keys are known as a key pair.

So, we create a key pair which consists of public key and private key and save it on our local machine.
#STEP 4: creating EC2 instance
We are creating an instance using a key and security group created in the above step. I have used Amazon Linux 2 AMI (Amazon Machine Image) and used the instance type as t2.micro .

To connect to the instance , used the key and public IP.Our requirement is to configure the instance. Provisioner will help in installing the required software such as Apache Web Server , PHP and Git. This will also start the httpd services.The provisioner will connect to the instance via remote SSH as we have provided the remote-exec provisioner in the code.
#STEP 5: creating an EBS volume and attaching it to an instance
We create a volume of 1 Gib of name "taskebs" in the same availability zone in which our EC2 instance is launched and then we attach the same volume to our running instance.
#STEP 6: create S3 bucket and adding object
S3 or Simple Storage Service is the only object storage service that allows you to block public access to all of your objects at the bucket or the account level with S3 Block Public Access.
#STEP 7:creating bucket policy and uploading files to s3
A bucket policy is a resource-based AWS Identity and Access Management (IAM) policy. You add a bucket policy to a bucket to grant other AWS accounts or IAM users access permissions for the bucket and the objects in it. Object permissions apply only to the objects that the bucket owner creates.
#STEP 9: creating Cloudfront distribution which is integrated with S3
CloudFront is a content delivery network (CDN) which is used for decreasing latency.I have integrated it with my s3 bucket "meharsagar".
#STEP 10: Format and mount the attached hard disk
Before copying or saving data to hard disk, it is formatted and mounted.Also before copying data of GitHub to /var/www/html/ folder see that /var/www/html folder is empty. The CloudFront path is copied to the test.html file so that in the index.html code the code will be changed at runtime.
#STEP 11: launching the site


Now here the complete code for the architecture using different AWS services gets done. Lets automate the entire code using our magic tool Terraform.

TERRAFORM COMMANDS USED:-
1.terraform init : it is used to initialise the code

2. terraform apply -auto-approve : applying the automation

3. terraform destroy -auto-approve : to destroy the complete architecture in just one command


THANK YOU FOR READING!!

