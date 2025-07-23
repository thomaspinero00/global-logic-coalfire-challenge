# 🚀 AWS Technical Challenge — Infrastructure with Terraform


## 1. Solution Overview

This project is a proof of concept (PoC) for deploying cloud infrastructure on AWS using Terraform, fulfilling all the requirements of the Global Logic/Coalfire challenge. The solution is 100% IaC, leverages open-source modules, and covers security, segmentation, automation, and cloud architecture best practices.

It is an AWS environment fully deployed with Terraform and designed to meet all the technical requirements of the challenge.

#### Includes:
- Robust network with segmentation (public/private, 2 AZs)
- ASG with Red Hat Linux web servers + automated Apache installation
- Standalone EC2 with Red Hat and SSH access control
- ALB balancing HTTP traffic
- S3 buckets for logs and images, with advanced lifecycle rules
- IAM roles and policies following the principle of least privilege


## 2. Solution Diagram

For maximum clarity and reproducibility, the architecture diagram is available in several formats:


#### PNG Image:

Quick, standard visualization for any user.


![Diagram image.](/diagrams/global-logic-diagram.png "Diagram image.")

#### Editable File (Draw.io / diagrams.net):
You’ll find the source file in the `/diagrams/` folder:

```
/diagrams/
  ├── global-logic-diagram.drawio
  └── global-logic-diagram.jpeg
```

You can open, edit, or import this .drawio directly in draw.io / diagrams.net to review, customize, or export it to other formats.

#### Direct Link for Online Viewing:

[View diagram online at diagrams.net](https://drive.google.com/file/d/1reruBtBDJLRf-gpgrso5OX96hykjZzVz/view?usp=sharing).

*The diagram follows the official AWS standard, identifying all components and their connectivity.*




## 3. Estructura del Proyecto
```
.
├── diagrams/
├── envs/
│   └── dev/
│       ├── backend.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── evidence/                   
├── remote-state/               # Infra for remote state management
│   ├── remote_state_setup.tf
├── scripts/
│   └── user_data_apache.sh     # User data script for EC2/ASG
├── .gitignore
└── README.md

```

 - The folder `diagrams/` contains the network diagram in image and *.drawio* format.
 - The folder `evidence/` contains the requested evidence captures.
 

## 4. Instrucciones de Despliegue


 Requirements:
 - AWS CLI configured
 - Terraform >= 1.4.x
 - Red Hat subscription on AWS
 - Git


### Steps:


#### Clone the repository

```
git clone https://github.com/thomaspinero00/global-logic-coalfire-challenge.git
cd global-logic-coalfire-challenge
```


#### Configure your variables

Edit variables.tf to configure your public IP for SSH.


#### Initialize Terraform


```
terraform init
```
#### Plan your deployment


```
terraform plan
```

#### Apply and create infrastructure


```
terraform apply
```

#### Access the EC2

Find the command to access via SSH in the output.

Use the generated command:


```
ssh -i "global-logic-key.pem" ec2-user@<EC2_PUBLIC_IP>
```



## 5. Design Decisions and Assumptions
 - Coalfire Modules: Use recommended open-source modules in the challenge description (VPC).
 
 - NAT Gateways: 2 NAT (1 per AZ) were created to maximize availability, justifying cost vs resilience.

 - Lifecycle S3: Policies are met exactly as requested (Glacier, delete, folders).

 - Red Hat AMI: Official and most recent (aws_ami data source) was used. To do this, subscription to AWS Marketplace was required.

 - Security: Minimum IAM roles, strict SGs. EC2 standalone only accessible via SSH from local user IP.

 - Simplified mode: All EC2 instances have the same userdata. This way, it is possible to use the standalone EC2 to check the internal functionality of the Apache services since these do not count with access outside the VPC.

  - User Data: Install and enable Apache, in addition to the AWS CLI (this last for testing the access of the EC2 to the corresponding buckets).

  - Outputs: Expose useful data such as DNS of ALB and Access via ssh to the Standalone EC2.




## 6. Potential Improvements

These improvement proposals are based on identifying certain operational gaps in the initial solution. These gaps represent missing functions or controls that could compromise availability, security, and user experience if not addressed. Therefore, adding proactive monitoring and strengthening traffic security are suggested, ensuring that the infrastructure not only meets the requirements of the challenge but is also resilient and ready for real-world production scenarios.

#### 1. Alarms and Proactive Monitoring

Currently, the infrastructure operates without automated observability mechanisms. An immediate improvement would be implementing custom dashboards and alarms in Amazon CloudWatch. For example, configuring alerts for high 5xx error rates, low instance availability, or unusual resource usage. This would allow for detecting incidents or bottlenecks before they impact the end user, enabling proactive responses and reducing downtime.

#### 2. Secure Access via HTTPS (TLS)

Right now, the environment exposes HTTP traffic without encryption (port 80). A relevant improvement would be to modify the ALB to support HTTPS, applying a managed TLS certificate (ACM). The HTTP listener (80) should be configured to permanently redirect to HTTPS (443), ensuring all external traffic is encrypted. The listener on 443 would then forward requests to the backend target group. This not only protects information in transit, but also follows best security and compliance practices.



## 7. Other Operational Gaps Considered

- The ASG does not allow direct SSH access, which aligns with best practices but could make quick debugging harder in real environments.
- Manual changes to SSH keys or subnets require reprovisioning.
- Infrastructure destruction should be supervised to avoid orphaned resources (for example, manual EIPs).




## 8. Evidence of Successful Deployment

I have attached screenshots of the terraform apply process, an EC2 instance running Apache, S3 buckets, the ALB online, and other pieces of evidence I considered relevant.




## 9. Comments and Notes on the Challenge

I chose to create the ASG target group outside the ALB module to maintain full flexibility and have clear outputs.

Troubleshooting the ASG health checks (unhealthy > healthy) required reviewing both security groups and routes/NAT gateways.

I prioritized meeting all the challenge requirements by using third-party modules, native AWS provider resources, and at least one Coalfire module.

The challenge was especially interesting when debugging issues related to module dependencies, missing outputs, and the unique behavior of each module. This troubleshooting was resolved by breaking up the creation of each service or resource.

Resource creation was mainly split as follows:
 - VPC: The creation of the VPC and the NAT for the private subnets was separated.
 - ALB: The main ALB resource, Target Groups, and listeners were created separately.



---------------

*Author: Thomas Piñero*

---------------



