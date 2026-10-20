
# Terraform Resources and Data Sources

## 1. What is a Resource?

A resource is a Terraform block used to create, update, or manage the lifecycle of an infrastructure object.

Examples:
- AWS EC2 instance
- AWS VPC
- AWS security group
- AWS S3 bucket

Example:

```hcl
resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-unique-demo-bucket-12345"
}
```

Here:
- `resource` declares a resource block.
- `aws_s3_bucket` is the resource type.
- `app_bucket` is the local name used to reference this resource in Terraform.
- `bucket` specifies the S3 bucket name.

Note: The bucket name must be globally unique if you actually apply this configuration.

## 2. What is a Data Source?

A data source allows Terraform to read information about an existing resource or other information provided by a service.

It does not manage the lifecycle of the object it reads.

Example:

```hcl
data "aws_vpc" "existing" {
  id = "vpc-0123456789abcdef0"
}
```

Here:
- `data` declares a data source.
- `aws_vpc` is the data source type.
- `existing` is the local name.
- `id` identifies the VPC to look up.

The VPC ID is a fictional example. Replace it with a real VPC ID in an authorized AWS account before running this configuration.

## 3. Resource vs Data Source

| Resource | Data Source |
|---|---|
| Manages an object's lifecycle | Reads information |
| Can create, update, or delete managed objects | Does not manage the lifecycle of the object it reads |
| Declared using `resource` | Declared using `data` |

Important: A resource can also refer to infrastructure that already exists if it is imported into Terraform state. A data source is not the same as importing a resource.

## 4. Real-World DevOps Example

Suppose an AWS VPC already exists, and we need to create a security group inside that VPC.

We can use a data source to look up the existing VPC and a resource to create the security group.

```hcl
data "aws_vpc" "existing" {
  id = "vpc-0123456789abcdef0"
}

resource "aws_security_group" "app" {
  name        = "app-security-group"
  description = "Security group for the application"
  vpc_id      = data.aws_vpc.existing.id
}
```

The data source retrieves the VPC information, and the resource manages the security group.

This example is for learning; it does not define any inbound or outbound security group rules.

## 5. Common Mistakes

- Using `resource` when you only need to look up an existing object.
- Assuming a data source imports an object into Terraform state.
- Assuming every resource must be newly created; existing objects can be imported.
- Using fictional resource IDs without replacing them before applying.

## 6. Interview Q&A

**Q: What is the difference between a Terraform resource and a data source?**

A: A resource is used to manage the lifecycle of infrastructure, including creating, updating, and deleting it. A data source reads information about an existing object or retrieves information from a provider. For example, I can use a VPC data source to look up an existing VPC and create a security group resource inside it.
