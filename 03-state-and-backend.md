
# Terraform State and Remote Backends

## 1. What Is Terraform State?

Terraform state is a record that maps the resources managed by Terraform to real infrastructure objects.

By default, Terraform stores state in a local file named `terraform.tfstate`.

Terraform uses state to understand which resources it manages and determine what changes are required.

## 2. Why Is State Important?

- Tracks resources managed by Terraform.
- Maps Terraform resource addresses to real infrastructure objects.
- Helps Terraform calculate infrastructure changes.
- Stores resource attributes that Terraform needs for future operations.

Important: State can contain sensitive information, so it must be protected.

## 3. What Is a Remote Backend?

A backend determines where Terraform stores its state.

A remote backend stores state in a remote service rather than only on a developer's local machine.

For AWS projects, we can use an Amazon S3 bucket as a remote backend.

Benefits:
- Team members can access shared state.
- State can be stored centrally.
- Access can be controlled using IAM permissions.
- S3 versioning can help recover earlier state versions.

## 4. Example: S3 Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket       = "company-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Explanation:

- `bucket`: Existing S3 bucket used to store state.
- `key`: Path of the state object inside the bucket.
- `region`: AWS region containing the bucket.
- `encrypt`: Enables encryption for state storage.
- `use_lockfile`: Turns on state locking (needs Terraform 1.10 or later).

This is an example configuration. The bucket must already exist, and the AWS identity needs the required permissions.

## 5. What Is State Locking?

State locking prevents multiple Terraform operations from modifying the same state simultaneously.

For example, if two engineers run `terraform apply` against the same state, locking helps prevent conflicting operations.

With the S3 backend, Terraform supports native locking through `use_lockfile = true`.

If a pipeline crashes, never remove a lock blindly. First verify that no Terraform operation is still running.

## 6. What Happens If State Is Lost?

Losing the state file does not automatically delete the actual infrastructure.

However, Terraform loses its record of the resources it manages.

Before running `terraform apply` with a new, empty state, inventory the existing infrastructure and recover the state from a backup or import the existing resources as appropriate.

Do not assume Terraform will automatically discover and adopt every existing resource.

## 7. Useful Commands

```bash
terraform state list
terraform state show aws_s3_bucket.app_bucket
terraform init
terraform plan
```

- `terraform state list`: Lists resources recorded in the current state.
- `terraform state show`: Displays the recorded attributes of a resource.
- `terraform init`: Initializes the working directory and backend.
- `terraform plan`: Previews proposed changes.

Use the actual resource address from your configuration when running `terraform state show`.

## 8. Best Practices

- Use a remote backend for team-managed infrastructure.
- Enable S3 bucket versioning and appropriate encryption.
- Restrict access to state using IAM.
- Separate state for independent environments such as Dev and Prod.
- Never commit state files or credentials to a public GitHub repository.
- Avoid editing state JSON manually.

## 9. Interview Q&A

**Q: Why do we use a remote backend in Terraform?**

A: A remote backend stores Terraform state centrally so authorized team members and CI/CD pipelines can work with the same state. In AWS, I can use an S3 backend with encryption, versioning, and state locking to improve collaboration and protect state.

**Q: What happens if Terraform state is lost?**

A: The infrastructure usually continues running, but Terraform loses its record of the resources it manages. I would first check for a valid backup or previous S3 object version. If recovery is not possible, I would inventory the infrastructure and carefully import existing resources into the correct state before applying further changes.
