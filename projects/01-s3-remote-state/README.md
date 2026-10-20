# Project 1 — S3 Bucket with Remote State

**Goal:** Move Terraform state off your computer and into a secure, versioned S3 bucket — the way real teams work.

| | |
|---|---|
| ⏱️ Time | 45 minutes |
| 💰 Cost | Less than $0.01 if you clean up the same day (state files are tiny) |
| 📖 Read first | [State and Backend](../../03-state-and-backend.md) |
| ✔️ Complete first | [Lab 03 — State and Drift](../../labs/03-state-and-drift/README.md) |

> 📝 **About the example output:** The code in this project has been checked with `terraform fmt` and `terraform validate`. The output shown in each step is an example — your bucket names and IDs will be different.

## What You'll Build

```text
bootstrap/          (its state: local file)
    │
    │ creates
    ▼
S3 state bucket     ✔ versioning
                    ✔ encryption
                    ✔ public access blocked
    ▲
    │ stores its state in
    │
app/                (creates an app bucket)
```

- **`bootstrap/`** creates the bucket that will hold state.
- **`app/`** creates a small app bucket, then moves its own state into the state bucket.

**Why two folders?** Terraform can't store its state in a bucket that doesn't exist yet. So we create the state bucket first, with a normal local state file. This "chicken and egg" problem is common in real projects.

## Before You Start

You need:

1. **Your own AWS account** for learning. Don't use a work account.
2. **The AWS CLI**, installed using the [official guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
3. **An IAM user or SSO login with permission to manage S3.** Don't use your root user.

Log in with `aws configure` or `aws sso login`, then check that it works:

```bash
aws sts get-caller-identity
```

You should see your account ID. If you see an error, fix your login before continuing.

> 🔐 **Never put AWS access keys in Terraform files.** Terraform finds your login automatically from the AWS CLI.

The code uses the `ap-south-1` (Mumbai) region. To use a different region, change the `default` of the `region` variable in both `main.tf` files.

---

## Part A — Create the State Bucket

### Step 1 — Read the Code

```bash
cd projects/01-s3-remote-state/bootstrap
```

Open [`bootstrap/main.tf`](bootstrap/main.tf). It creates four things:

| Resource | Why |
|---|---|
| `aws_s3_bucket` | The bucket that holds state files |
| `aws_s3_bucket_versioning` | Keeps old versions of state, so you can recover from mistakes |
| `aws_s3_bucket_server_side_encryption_configuration` | Encrypts state at rest |
| `aws_s3_bucket_public_access_block` | Makes sure the bucket can never be public — state can contain secrets |

Two things worth noticing:

- `bucket_prefix = "tf-learning-state-"` — S3 bucket names must be unique across **all** AWS accounts, so we let AWS add a unique ending.
- `force_destroy = true` — lets `terraform destroy` delete the bucket even when it has files in it. It's here to make clean-up easy. **Never use it on a real state bucket.**

The `default_tags` block in the provider adds `Project` and `ManagedBy` tags to every resource, so you can easily find them in the AWS Console.

### Step 2 — Create the Bucket

```bash
terraform init
terraform plan
```

✅ **Example output:**

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

Read the plan, then apply:

```bash
terraform apply
```

Type `yes`.

✅ **Example output:**

```text
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

state_bucket_name = "tf-learning-state-20261020120000000000000001"
```

📋 **Copy your `state_bucket_name`** — you'll need it in Part B.

### Step 3 — Check in the AWS Console

Open **S3** in the AWS Console (make sure the right region is selected) and click your `tf-learning-state-...` bucket:

- **Properties** tab → **Bucket Versioning** shows **Enabled**.
- **Permissions** tab → **Block all public access** shows **On**.

> ℹ️ The bootstrap's own state stays in a local `terraform.tfstate` file in the `bootstrap/` folder. Keep it — you need it to destroy the bucket later. This repository's `.gitignore` stops it from being committed.

---

## Part B — Move the App's State to S3

### Step 4 — Create the App with Local State

```bash
cd ../app
terraform init
terraform apply
```

Type `yes`.

✅ **Example output:**

```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

app_bucket_name = "tf-learning-app-20261020120500000000000002"
```

Right now the app's state is in a local `terraform.tfstate` file, just like in the labs.

### Step 5 — Tell Terraform to Use S3

Create a new file called `backend.tf` in the `app/` folder:

```hcl
terraform {
  backend "s3" {
    bucket       = "PASTE_YOUR_STATE_BUCKET_NAME_HERE"
    key          = "project-1/app/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Replace `PASTE_YOUR_STATE_BUCKET_NAME_HERE` with your `state_bucket_name` from Step 2.

| Setting | Meaning |
|---|---|
| `bucket` | Which bucket stores the state |
| `key` | The file path inside the bucket. Each project or environment gets its own key. |
| `region` | The bucket's region |
| `encrypt` | Encrypt the state file |
| `use_lockfile` | Stop two people changing the same state at the same time (needs Terraform 1.10 or later) |

> ⚠️ You can't use variables like `var.region` inside a `backend` block. Terraform reads the backend before it reads variables, so the values must be written in directly.

### Step 6 — Move the State

```bash
terraform init -migrate-state
```

Terraform asks:

```text
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value:
```

Type `yes`.

✅ **Example output:**

```text
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
...
Terraform has been successfully initialized!
```

### Step 7 — Check It Worked

Terraform still knows about your app bucket:

```bash
terraform state list
```

```text
aws_s3_bucket.app
aws_s3_bucket_public_access_block.app
```

Now look at the local `terraform.tfstate` file — it's **empty** (0 bytes). The real state now lives in S3.

In the AWS Console, open your state bucket. You'll find the state file at `project-1/app/terraform.tfstate`.

Finally, confirm nothing needs to change:

```bash
terraform plan
```

```text
No changes. Your infrastructure matches the configuration.
```

🎉 Your app now uses remote state. Anyone with the right AWS permissions — a teammate or a CI/CD pipeline — could now work with the same state.

---

## Part C — See Locking and Versioning

### Step 8 — See State Locking

Open **two terminals**, both in the `app/` folder.

In **terminal 1**, start an apply but **don't answer** the question yet:

```bash
terraform apply
```

While it's waiting for `yes`, run this in **terminal 2**:

```bash
terraform plan
```

Terminal 2 fails with an error similar to:

```text
Error: Error acquiring the state lock
```

Terraform is protecting the state: only one operation can use it at a time. If you look in the state bucket now, you'll see a `terraform.tfstate.tflock` file next to the state file — that's the lock.

In **terminal 1**, type `no` to cancel. The lock is released automatically.

### Step 9 — See State Versions

Add a tag to the app bucket in `app/main.tf`:

```hcl
resource "aws_s3_bucket" "app" {
  bucket_prefix = "tf-learning-app-"

  # Learning only: lets "terraform destroy" delete the bucket even when it contains files.
  force_destroy = true

  tags = {
    Purpose = "learning"
  }
}
```

```bash
terraform apply
```

Type `yes`. Then in the AWS Console, open the state bucket, go to `project-1/app/`, and turn on **Show versions**. You'll see more than one version of `terraform.tfstate`.

If the state is ever damaged, you can restore an earlier version from here. That's why versioning matters.

---

## Step 10 — Clean Up

⚠️ **Order matters.** Destroy the app first, then the state bucket. If you destroy the state bucket first, you'll delete the app's state — and Terraform will no longer know the app bucket exists.

**1. Destroy the app:**

```bash
cd ../app
terraform destroy
```

Type `yes`.

**2. Destroy the state bucket:**

```bash
cd ../bootstrap
terraform destroy
```

Type `yes`.

✅ **Example output:**

```text
Destroy complete! Resources: 4 destroyed.
```

**3. Check:** In the AWS Console, make sure no `tf-learning-` buckets remain.

**4. Tidy up locally:** Delete `app/backend.tf` — the bucket it points to no longer exists. If you want to run the project again, also delete the `app/.terraform` folder before starting.

## 🔧 Common Errors

**No valid credential sources found**
Terraform can't find your AWS login. Run `aws configure` or `aws sso login`, then check with `aws sts get-caller-identity`.

**AccessDenied**
Your AWS user doesn't have permission to manage S3. Ask your account admin, or check the IAM permissions of your learning user.

**The S3 bucket in `backend.tf` doesn't exist**
The bucket name in `backend.tf` is wrong. Copy it again from `terraform output` in the `bootstrap/` folder.

**Backend configuration changed**
You edited `backend.tf` after running `init`. Run `terraform init -migrate-state` again and read the question carefully.

**Error acquiring the state lock**
Another Terraform operation is using the state. Wait for it to finish. Only consider `terraform force-unlock` if you're **certain** nothing else is running — see [Interview Q27](../../08-terraform-interview-questions.md).

**I destroyed the state bucket first**
The app bucket still exists, but its state is gone. Delete the `tf-learning-app-...` bucket manually in the AWS Console. This is exactly the "lost state" situation from Lab 03 — now with real cloud resources.

## 🧪 Try It Yourself

1. Change `key` in `backend.tf` to `project-1/app-v2/terraform.tfstate` and run `terraform init -migrate-state`. Where does the state end up?
2. Using the **Show versions** view, find out how many times you've applied the app configuration.
3. Why is it a bad idea to store the bootstrap's state in the same bucket it creates?

Remember to clean up when you finish.

## ✅ What You Learned

- Remote state lets teams and pipelines share one source of truth.
- A state bucket needs versioning, encryption, and blocked public access.
- `terraform init -migrate-state` moves existing state to a new backend.
- `use_lockfile = true` stops two operations from changing state at the same time.
- Backend blocks can't use variables.
- Clean-up order matters when one configuration depends on another.

**Interview practice:** Try answering [Q5–Q8 and Q21–Q27](../../08-terraform-interview-questions.md) using what you did in this project.

**Next:** [Project 2 — Reusable VPC Module with Dev and Prod](../02-vpc-module-dev-prod/README.md)
