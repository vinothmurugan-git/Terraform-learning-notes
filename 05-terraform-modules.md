
# Terraform Modules

## 1. What Is a Terraform Module?

A Terraform module is a collection of Terraform configuration files in a directory that work together to manage infrastructure.

The root module is the directory where we run Terraform commands. A child module is a module called from another module.

## 2. Why Do We Use Modules?

- Reuse infrastructure code.
- Avoid duplicating resource configurations.
- Standardize infrastructure across environments.
- Make large Terraform projects easier to maintain.
- Separate infrastructure components such as VPC, ECS, and RDS.

## 3. Example Project Structure

```text
terraform-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── dev.tfvars
├── prod.tfvars
└── modules/
    └── s3-bucket/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

The root module calls the reusable S3 module.

## 4. Example: Create a Reusable S3 Module

### modules/s3-bucket/variables.tf

```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}
```

### modules/s3-bucket/main.tf

```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}
```

### modules/s3-bucket/outputs.tf

```hcl
output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
```

### Root module: main.tf

```hcl
module "app_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = var.bucket_name
}
```

The root module must also declare the `bucket_name` input variable and configure the AWS provider.

This example illustrates module structure; an actual bucket name must be globally unique.

## 5. How Does It Work?

1. The root module calls the child module.
2. It passes input variables to the module.
3. The child module creates or manages the defined resources.
4. Outputs expose selected values back to the root module.

## 6. Real-World DevOps Example

Suppose our organization has several applications deployed to AWS ECS.

Instead of writing the entire ECS infrastructure configuration separately for every application, we can create a reusable ECS module.

Each application passes its own settings, such as CPU, memory, container port, and desired task count.

The shared module keeps the infrastructure structure consistent while allowing application-specific configuration.

## 7. Common Mistakes

- Hardcoding environment-specific values inside a reusable module.
- Forgetting to declare required input variables.
- Forgetting to expose outputs needed by the root module.
- Using modules without understanding the resources they create.
- Assuming modules automatically isolate state. They do not.

## 8. Interview Q&A

**Q: Why do you use Terraform modules?**

A: I use Terraform modules to organize and reuse infrastructure code. For example, I can create a reusable ECS module and call it for multiple applications with different configurations. This reduces duplication, improves consistency, and makes infrastructure easier to maintain.
