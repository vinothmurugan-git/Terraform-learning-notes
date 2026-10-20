
# Terraform Fundamentals

## 1. What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool that allows us to provision and manage infrastructure using configuration files.

Instead of manually creating AWS resources through the AWS Console, we can define them in Terraform configuration files.

## 2. Why do we use Terraform?

- Automation: Create infrastructure automatically.
- Consistency: Use the same configuration across environments.
- Version control: Track infrastructure changes using Git.
- Reusability: Reuse configurations through modules.
- Collaboration: Share infrastructure code with the team.

## 3. Basic Terraform Workflow

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

- `terraform init`: Initializes the working directory.
- `terraform validate`: Checks whether the configuration is valid.
- `terraform plan`: Previews the proposed infrastructure changes.
- `terraform apply`: Applies the changes to infrastructure.

## 4. Real-World DevOps Example

Suppose we need to create an AWS EC2 instance for a development environment.

Instead of creating it manually in the AWS Console, we define the required configuration in Terraform.

Terraform compares the configuration with its state and the actual infrastructure, then proposes the necessary changes.

After reviewing the plan, we apply it to create the instance.

## 5. Interview Answer

Terraform is an Infrastructure as Code tool used to provision and manage cloud infrastructure through configuration files. In my DevOps workflow, I can use Terraform to automate AWS resource creation, maintain consistent Dev and Prod environments, and manage infrastructure changes through version control.

## 6. Important Safety Notes

- Always review `terraform plan` before applying changes.
- Never commit AWS credentials or secrets.
- Never commit Terraform state files to a public repository.
- Use separate state files for independent environments when appropriate.
