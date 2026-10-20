
# Terraform Variables and Outputs

## 1. What Are Input Variables?

Input variables allow us to pass values into Terraform configurations instead of hardcoding them.

For example, Dev and Prod environments might need different EC2 instance types.

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

Use the variable in a resource:

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

Here, `var.instance_type` references the input variable.

The example also uses `var.ami_id`, so an `ami_id` variable must be declared separately.

## 2. What Are Outputs?

Outputs expose selected values from Terraform after resources are created or data is retrieved.

For example:

```hcl
output "instance_id" {
  description = "ID of the application EC2 instance"
  value       = aws_instance.app.id
}
```

Useful commands:

```bash
terraform output
terraform output instance_id
```

Outputs can help us retrieve resource IDs, IP addresses, or other useful values.

Important: Outputs are not automatically secret. Marking an output as sensitive hides it in some CLI displays, but its value may still be stored in Terraform state.

## 3. What Are Variable Definition Files?

Terraform supports `.tfvars` files to provide environment-specific input values.

Example `dev.tfvars`:

```hcl
instance_type = "t3.micro"
ami_id        = "ami-0123456789abcdef0"
```

Example `prod.tfvars`:

```hcl
instance_type = "t3.small"
ami_id        = "ami-0123456789abcdef0"
```

The AMI IDs above are illustrative placeholders. Use valid AMIs for the target AWS region before deploying.

To select a file:

```bash
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

Use the appropriate variable file for the intended environment.

## 4. Real-World DevOps Example

Suppose the same application needs different infrastructure settings in Dev and Prod.

Instead of maintaining two copies of the same resource configuration, we can keep reusable Terraform code and supply different variable values.

This reduces duplication and makes configuration easier to maintain.

For independent environments, use appropriately separated state and deployment workflows as well. Different `.tfvars` files alone do not isolate Terraform state.

## 5. Common Mistakes

- Hardcoding values that should vary by environment.
- Forgetting to declare a variable referenced by a resource.
- Committing passwords, tokens, or other secrets in `.tfvars` files.
- Assuming different variable files automatically create separate state.
- Assuming `sensitive = true` removes secret values from state.

## 6. Interview Q&A

**Q: How do you manage different configurations for Dev and Prod in Terraform?**

A: I use reusable Terraform configurations with input variables and environment-specific variable files. For example, Dev and Prod can use different instance types without duplicating the resource code. I also keep their state and deployment workflows appropriately separated to avoid accidentally modifying the wrong environment.
