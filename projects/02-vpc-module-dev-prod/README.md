# Project 2 — Reusable VPC Module with Dev and Prod

**Goal:** Write a VPC module once, use it for two environments, and keep their state completely separate.

| | |
|---|---|
| ⏱️ Time | 45 minutes |
| 💰 Cost | Free — VPCs, subnets, internet gateways, and route tables have no charge |
| 📖 Read first | [Terraform Modules](../../05-terraform-modules.md) |
| ✔️ Complete first | [Project 1](../01-s3-remote-state/README.md) and [Lab 02](../../labs/02-variables-and-outputs/README.md) |

> 📝 **About the example output:** The code in this project has been checked with `terraform fmt`, `terraform validate`, and an offline test. The output shown in each step is an example — your IDs will be different.

## What You'll Build

```text
modules/vpc/            ← written once
    │
    ├── used by environments/dev/
    │       VPC 10.0.0.0/16, 1 subnet
    │       state: project-2/dev/terraform.tfstate
    │
    └── used by environments/prod/
            VPC 10.1.0.0/16, 2 subnets
            state: project-2/prod/terraform.tfstate
```

Each VPC contains:

- A **VPC** — your own private network in AWS
- An **internet gateway** — the door to the internet
- **Public subnets** — one per availability zone
- A **route table** — sends internet traffic through the gateway

**Remember Lab 02?** Switching from dev to prod values deleted the dev file, because both used the same state. Here, each environment has its **own folder and its own state**, so that can't happen.

> 💰 We don't create a **NAT gateway**. It's common in real VPCs, but it costs around $30+ per month even when idle.

## Before You Start

You need the **state bucket from Project 1**. If you already cleaned it up, create it again:

```bash
cd projects/01-s3-remote-state/bootstrap
terraform init
terraform apply
```

Copy the `state_bucket_name` output.

---

## Step 1 — Read the Module

Open the [`modules/vpc/`](modules/vpc) folder. A module is normally split into three files:

| File | Contains |
|---|---|
| [`variables.tf`](modules/vpc/variables.tf) | The inputs: `name`, `vpc_cidr`, `public_subnets` |
| [`main.tf`](modules/vpc/main.tf) | The resources |
| [`outputs.tf`](modules/vpc/outputs.tf) | The values it gives back: `vpc_id`, `public_subnet_ids` |

The new idea is **`for_each`**. It creates one resource for each item in a map:

```hcl
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value
  ...
}
```

If `public_subnets` is:

```hcl
{
  "ap-south-1a" = "10.1.1.0/24"
  "ap-south-1b" = "10.1.2.0/24"
}
```

Terraform creates two subnets, called `aws_subnet.public["ap-south-1a"]` and `aws_subnet.public["ap-south-1b"]`. `each.key` is the zone and `each.value` is the IP range.

Notice the module has **no provider block and no hardcoded environment values**. The environment that calls it decides those.

## Step 2 — Read an Environment

Open [`environments/dev/main.tf`](environments/dev/main.tf). The important part:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name     = "dev"
  vpc_cidr = "10.0.0.0/16"

  public_subnets = {
    "ap-south-1a" = "10.0.1.0/24"
  }
}
```

`source` points to the module folder. The other lines are the module's inputs. [`environments/prod/main.tf`](environments/prod/main.tf) is the same, with a different IP range and two subnets.

The IP ranges don't overlap (`10.0.x.x` and `10.1.x.x`). That keeps the option open to connect the two networks later.

## Step 3 — Give Each Environment Its Own State

Create a file called `backend.tf` in **`environments/dev/`**:

```hcl
terraform {
  backend "s3" {
    bucket       = "PASTE_YOUR_STATE_BUCKET_NAME_HERE"
    key          = "project-2/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Create another `backend.tf` in **`environments/prod/`** — same bucket, but a **different key**:

```hcl
terraform {
  backend "s3" {
    bucket       = "PASTE_YOUR_STATE_BUCKET_NAME_HERE"
    key          = "project-2/prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Replace the bucket name in both files. The different `key` is what keeps dev and prod state separate.

## Step 4 — Deploy Dev

```bash
cd projects/02-vpc-module-dev-prod/environments/dev
terraform init
terraform plan
```

`init` now also installs the module. ✅ **Example output:**

```text
Initializing modules...
- vpc in ../../modules/vpc
...
Plan: 5 to add, 0 to change, 0 to destroy.
```

Five resources: VPC, internet gateway, 1 subnet, route table, and 1 route table association.

```bash
terraform apply
```

Type `yes`. ✅ **Example output:**

```text
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

public_subnet_ids = {
  "ap-south-1a" = "subnet-0abc1234def567890"
}
vpc_id = "vpc-0123456789abcdef0"
```

## Step 5 — Deploy Prod

```bash
cd ../prod
terraform init
terraform apply
```

Read the plan before typing `yes`. ✅ **Example output:**

```text
Plan: 7 to add, 0 to change, 0 to destroy.
...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
```

Seven this time, because prod has two subnets and two associations. **Same module, different result.**

## Step 6 — Check in the AWS Console

- **VPC → Your VPCs:** `dev-vpc` and `prod-vpc`.
- **VPC → Subnets:** one `dev-public-...` subnet and two `prod-public-...` subnets.
- **S3 → your state bucket → `project-2/`:** separate `dev/` and `prod/` state files.

## Step 7 — The Key Moment: Destroy Dev Only

```bash
cd ../dev
terraform destroy
```

Type `yes`. ✅ **Example output:**

```text
Destroy complete! Resources: 5 destroyed.
```

Now check prod:

```bash
cd ../prod
terraform plan
```

✅ **What you should see:**

```text
No changes. Your infrastructure matches the configuration.
```

**Prod was not touched.** Dev's destroy only knew about dev's state. Compare that with Lab 02, where one change deleted the other environment.

## Step 8 — Clean Up

Prod is still running. Destroy it, then the state bucket:

```bash
terraform destroy
cd ../../../01-s3-remote-state/bootstrap
terraform destroy
```

Type `yes` each time. In the AWS Console, check that no `dev-vpc`, `prod-vpc`, or `tf-learning-` buckets remain.

## 🔧 Common Errors

**`Error: Module not installed`**
You haven't run `terraform init` in this environment folder, or you added the module after running it. Run `terraform init`.

**`VpcLimitExceeded`**
AWS allows 5 VPCs per region by default. Delete VPCs you don't need, or use a different region.

**Invalid availability zone**
The zone names in `public_subnets` must belong to your region. If you changed the region, change `ap-south-1a`/`ap-south-1b` too.

**Subnet IP range error (`InvalidSubnet.Range` or `InvalidSubnet.Conflict`)**
Each subnet's range must be inside the VPC range and must not overlap with other subnets.

**Wrong environment changed**
Check which folder you're in before running `apply` or `destroy`. Running `pwd` takes one second and can save your production environment.

## 🧪 Try It Yourself

1. Add `"ap-south-1c" = "10.0.3.0/24"` to dev's `public_subnets`. How many resources does the plan add?
2. Then remove `ap-south-1a` from dev. Does Terraform replace the other subnets? (With `for_each`, it shouldn't — each subnet is identified by its zone, not its position.)
3. Add a third environment, `staging`, with `10.2.0.0/16`. Which files do you need to create?

Remember to clean up when you finish.

## ✅ What You Learned

- A module is written once and reused with different inputs.
- Modules have `variables.tf`, `main.tf`, and `outputs.tf`, and no hardcoded environment values.
- `for_each` creates one resource per map item, identified by a stable key.
- Separate folders and separate state keys keep environments isolated.
- Destroying one environment doesn't affect another.

**Interview practice:** Try answering [Q11, Q12, Q30, and Q32](../../08-terraform-interview-questions.md) using what you did in this project.

**Next:** [Project 3 — Terraform with GitHub Actions](../03-github-actions/README.md)
