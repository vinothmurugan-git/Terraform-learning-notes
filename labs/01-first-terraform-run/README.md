# Lab 01 — Your First Terraform Run

**Goal:** Run the full Terraform workflow from start to finish and see what each command does.

| | |
|---|---|
| ⏱️ Time | 15 minutes |
| 💰 Cost | Free — no cloud account needed |
| 📖 Read first | [Terraform Fundamentals](../../01-terraform-fundamentals.md) |

In this lab, Terraform creates a simple text file on your computer instead of a cloud resource. The workflow is exactly the same one you'll use later with AWS.

## Before You Start

Install Terraform by following the [official installation guide](https://developer.hashicorp.com/terraform/install), then check it works:

```bash
terraform version
```

You should see something like `Terraform v1.13.3`. Any recent version is fine.

## Step 1 — Get the Code

Clone the repository and move into this lab's folder:

```bash
git clone https://github.com/vinothmurugan-git/Terraform-learning-notes.git
cd Terraform-learning-notes/labs/01-first-terraform-run
```

Or create an empty folder yourself and copy [`main.tf`](main.tf) into it.

Open `main.tf` and read it:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Hello from Terraform!\n"
}
```

- The `terraform` block says which **provider** we need. A provider is a plugin that lets Terraform manage something — here, files on your computer. Later we'll use the `aws` provider in the same way.
- `version = "~> 2.5"` means "version 2.5 or newer, but below 3.0". Pinning versions keeps your code working when providers release breaking changes.
- The `resource` block describes **what we want**: a file called `hello.txt` with some text inside.

## Step 2 — Initialize

```bash
terraform init
```

✅ **What you should see:**

```text
- Installed hashicorp/local v2.9.1 (signed by HashiCorp)
...
Terraform has been successfully initialized!
```

`init` downloads the provider into a hidden `.terraform/` folder and creates `.terraform.lock.hcl`, which records the exact provider version chosen.

## Step 3 — Format and Validate

```bash
terraform fmt
terraform validate
```

✅ **What you should see:**

```text
Success! The configuration is valid.
```

- `fmt` tidies the code layout. It prints nothing if the file is already formatted.
- `validate` checks for mistakes in the code. It does not create anything.

## Step 4 — Plan

```bash
terraform plan
```

✅ **What you should see:**

```text
  # local_file.hello will be created
  + resource "local_file" "hello" {
      + content              = <<-EOT
            Hello from Terraform!
        EOT
      + filename             = "./hello.txt"
      + id                   = (known after apply)
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

The `+` symbol means **create**. Nothing has been created yet — `plan` only shows what *would* happen. Check your folder: there is no `hello.txt` yet.

## Step 5 — Apply

```bash
terraform apply
```

Terraform shows the plan again and asks:

```text
Do you want to perform these actions?
  Enter a value:
```

Type `yes` and press Enter.

✅ **What you should see:**

```text
local_file.hello: Creating...
local_file.hello: Creation complete after 0s [id=4518d4c8a76b1bc887db3d806e45012b4c276e5a]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Check the file Terraform created:

```bash
cat hello.txt
```

(On Windows Command Prompt, use `type hello.txt`.)

```text
Hello from Terraform!
```

## Step 6 — See What Terraform Remembers

```bash
terraform state list
```

✅ **What you should see:**

```text
local_file.hello
```

Terraform saved a record of what it created in a new file called `terraform.tfstate`. This is the **state file**. Lab 03 explores it in detail.

## Step 7 — Change Something

In `main.tf`, change the text:

```hcl
  content  = "Hello again from Terraform!\n"
```

Run a plan:

```bash
terraform plan
```

✅ **What you should see:**

```text
  # local_file.hello must be replaced
-/+ resource "local_file" "hello" {
      ~ content              = <<-EOT # forces replacement
          - Hello from Terraform!
          + Hello again from Terraform!
        EOT
      ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

`-/+` means **replace**: Terraform will delete the old file and create a new one. Some changes can update a resource in place, but others force a replacement. Always read the plan to see which one you're getting — with real servers or databases, a replacement can mean downtime or data loss.

Run `terraform apply`, type `yes`, and check `hello.txt` again.

## Step 8 — Clean Up

```bash
terraform destroy
```

Type `yes` when asked.

✅ **What you should see:**

```text
local_file.hello: Destroying... [id=...]
local_file.hello: Destruction complete after 0s

Destroy complete! Resources: 1 destroyed.
```

`hello.txt` is gone. Building the habit of cleaning up now will save you money when you start using AWS.

## 🔧 Common Errors

**`terraform: command not found`**
Terraform isn't installed, or it isn't on your `PATH`. Repeat the installation guide, then open a new terminal.

**`Error: Inconsistent dependency lock file` … `run: terraform init`**
You ran `plan` or `apply` before `init`. Run `terraform init` first.

**`Error: No configuration files`**
You're in the wrong folder. Use `cd` to move into the folder that contains `main.tf`.

## 🧪 Try It Yourself

1. Change `filename` to `"${path.module}/welcome.txt"` and run `terraform plan`. Is it an update or a replacement?
2. Add a second `local_file` resource with a different name and filename. What does the plan say?
3. Run `terraform apply` twice in a row without changing anything. What does the second run say?

Remember to run `terraform destroy` when you finish.

## ✅ What You Learned

- `init` downloads providers, `plan` previews, `apply` makes changes, and `destroy` removes everything.
- `plan` never changes anything — it's always safe to run.
- Terraform remembers what it created in a state file.
- Some changes replace a resource instead of updating it, and the plan tells you which.

**Next:** [Lab 02 — Variables and Outputs](../02-variables-and-outputs/README.md)
