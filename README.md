# ECS Fargate 7 Microservices - Ready Repo

This archive contains:
- 7 microservices under microservices/ (auth, users, orders, products, payments, notifications, reports)
- a root buildspec.yml which builds & pushes all images to ECR
- infra/ folder containing HCP Terraform files to provision AWS resources (VPC, ECR, ECS, ALB, CodeBuild, CodePipeline)

IMPORTANT:
- Replace placeholders in infra/versions.tf (YOUR_HCP_ORG) and infra/providers/variables as needed.
- Add workspace variables in Terraform Cloud for AWS credentials and github repo/token.

To deploy:
1. Push this repository to GitHub
2. Create Terraform Cloud workspace and connect to this repo
3. Set workspace variables (AWS keys, github token)
4. Run Terraform plan & apply in Terraform Cloud
5. Trigger pipeline by pushing code to main (or it will auto-run)

