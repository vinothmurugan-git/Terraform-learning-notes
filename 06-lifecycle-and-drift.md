
# Terraform Lifecycle Rules and Infrastructure Drift

## 1. What Is Infrastructure Drift?

Infrastructure drift occurs when the actual infrastructure differs from the configuration or expected state managed by Terraform.

For example, Terraform manages an EC2 instance with a particular instance type. Someone changes the instance type manually in the AWS Console.

The actual infrastructure may now differ from the Terraform configuration.

We can run `terraform plan` to identify proposed changes that would reconcile the infrastructure with the configuration.

## 2. What Is the Lifecycle Meta-Argument?

The `lifecycle` meta-argument controls certain aspects of how Terraform handles resource changes.

Common lifecycle rules include:

- `prevent_destroy`
- `create_before_destroy`
- `ignore_changes`

## 3. prevent_destroy

This rule prevents Terraform from planning the destruction of a resource while the rule remains in its applicable configuration.

Example:

```hcl
resource "aws_s3_bucket" "important" {
  bucket = "my-unique-important-bucket-12345"

  lifecycle {
    prevent_destroy = true
  }
}
```

If a Terraform change would destroy this bucket, Terraform blocks that operation while this rule applies.

Important: This is not a complete deletion-protection mechanism. Removing the resource configuration or the lifecycle rule can remove this protection. Use appropriate cloud-side safeguards and backups too.

## 4. create_before_destroy

This rule tells Terraform to create a replacement resource before destroying the old one when replacement is required and the provider and infrastructure allow it.

Example:

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}
```

This can reduce downtime during replacement, but it is not always possible. For example, resource naming conflicts, quotas, or other dependencies may prevent both resources from existing simultaneously.

## 5. ignore_changes

This rule tells Terraform to ignore changes to specified resource attributes when planning updates to an existing resource.

Example:

```hcl
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    ignore_changes = [tags]
  }
}
```

In this example, Terraform ignores differences in the `tags` attribute when deciding whether to update the instance.

Use this rule carefully. Ignoring changes can hide important drift and cause actual infrastructure to differ from your intended configuration.

## 6. How Do You Detect and Handle Drift?

1. Run `terraform plan` using the correct configuration, workspace, variables, and state.
2. Review the proposed changes.
3. Confirm whether the difference was intentional or accidental.
4. If the manual change was unauthorized, decide whether to restore the intended configuration or reconcile the code with the approved change.
5. Apply only after reviewing and approving the plan.

Terraform can detect many out-of-band changes, but detection depends on the resource, provider, and available refresh information.

## 7. Real-World DevOps Example

Suppose an engineer manually changes an ECS task definition or an EC2 instance through the cloud console.

During the next Terraform plan, Terraform may propose changes to bring the infrastructure back in line with the configuration.

Before applying, I would investigate why the manual change happened and confirm the desired state with the team.

I would not blindly apply a plan that could overwrite an intentional production change.

## 8. Common Mistakes

- Applying a plan without understanding why drift occurred.
- Assuming `prevent_destroy` protects a resource from every deletion path.
- Using `ignore_changes` to hide unexplained differences.
- Assuming `create_before_destroy` always guarantees zero downtime.
- Running Terraform against the wrong environment or state.

## 9. Interview Q&A

**Q: How do you handle infrastructure drift in Terraform?**

A: I run `terraform plan` against the correct environment and state to identify differences between the configuration and actual infrastructure. I investigate whether the change was intentional, reconcile the configuration when appropriate, and apply the reviewed plan only after approval. For critical resources, I also use suitable lifecycle rules and cloud-side protections.
