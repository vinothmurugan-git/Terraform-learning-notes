# Lab 02 — Variables and Outputs

**Goal:** Pass different values into the same Terraform code, and read results back out.

| | |
|---|---|
| ⏱️ Time | 20 minutes |
| 💰 Cost | Free — no cloud account needed |
| 📖 Read first | [Variables and Outputs](../../04-variables-and-outputs.md) |
| ✔️ Complete first | [Lab 01](../01-first-terraform-run/README.md) |

## Step 1 — Read the Code

From the Lab 01 folder, move into this lab's folder:

```bash
cd ../02-variables-and-outputs
```

Open [`main.tf`](main.tf). It has three new parts.

**Variables** — inputs to your code:

```hcl
variable "environment" {
  description = "Name of the environment, for example dev or prod"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "server_count" {
  description = "Number of servers the application needs"
  type        = number
  default     = 1
}
```

- `environment` and `server_count` have a **default**, so they're optional.
- `app_name` has **no default**, so you must provide a value.
- `type` tells Terraform what kind of value to expect: text (`string`) or a number (`number`).

**Using variables** — `var.<name>` reads a variable's value:

```hcl
resource "local_file" "config" {
  filename = "${path.module}/${var.environment}-config.txt"
  content  = <<-EOT
    App:         ${var.app_name}
    Environment: ${var.environment}
    Servers:     ${var.server_count}
  EOT
}
```

`${ ... }` inserts a value into text. `<<-EOT ... EOT` is a way to write text that spans several lines.

**Outputs** — values Terraform shows you after `apply`:

```hcl
output "config_file" {
  description = "Path of the generated config file"
  value       = local_file.config.filename
}

output "summary" {
  description = "One-line summary of the configuration"
  value       = "${var.app_name} runs ${var.server_count} server(s) in ${var.environment}"
}
```

## Step 2 — Forget a Required Variable

```bash
terraform init
terraform plan
```

Terraform notices `app_name` has no value and asks you for one:

```text
var.app_name
  Name of the application

  Enter a value:
```

Press `Ctrl+C` to cancel. Typing values by hand is easy to get wrong, so let's pass them properly.

## Step 3 — Pass a Value with `-var`

```bash
terraform apply -var="app_name=shop"
```

Type `yes` when asked.

✅ **What you should see:**

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

config_file = "./dev-config.txt"
summary = "shop runs 1 server(s) in dev"
```

Check the file:

```bash
cat dev-config.txt
```

```text
App:         shop
Environment: dev
Servers:     1
```

`environment` and `server_count` used their defaults.

## Step 4 — Read the Outputs Again

You can read outputs at any time without running `apply`:

```bash
terraform output
terraform output -raw summary
```

✅ **What you should see:**

```text
config_file = "./dev-config.txt"
summary = "shop runs 1 server(s) in dev"
shop runs 1 server(s) in dev
```

`-raw` prints just the value, without quotes — handy in scripts.

## Step 5 — Use a Variable File

Typing many `-var` options gets messy. Instead, create a file called `prod.tfvars` in this folder:

```hcl
app_name     = "shop"
environment  = "prod"
server_count = 3
```

> **Note:** This repository's `.gitignore` excludes `*.tfvars` files, because in real projects they often contain secrets. That's why you create this file yourself.

Now run a plan with it:

```bash
terraform plan -var-file="prod.tfvars"
```

✅ **What you should see:**

```text
  # local_file.config must be replaced
      ~ content              = <<-EOT # forces replacement
      ~ filename             = "./dev-config.txt" -> "./prod-config.txt" # forces replacement

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ config_file = "./dev-config.txt" -> "./prod-config.txt"
  ~ summary     = "shop runs 1 server(s) in dev" -> "shop runs 3 server(s) in prod"
```

## Step 6 — The Important Lesson

Look closely at that plan: **`1 to destroy`**. Terraform wants to *delete* the dev file and create a prod file.

Apply it and see for yourself:

```bash
terraform apply -var-file="prod.tfvars"
ls
```

`dev-config.txt` is gone. Only `prod-config.txt` remains.

**Why?** Both runs used the same folder, so they share **one state file**. Terraform thinks there is one config file, and you just told it to be the prod one.

⚠️ With real infrastructure, this mistake could delete your dev environment — or your production one. A different `.tfvars` file changes the *values*, not *where Terraform keeps its records*. Real projects keep dev and prod in separate state. You'll practise that in the Build projects.

## Step 7 — Clean Up

```bash
terraform destroy -var-file="prod.tfvars"
```

Type `yes`. Then delete `prod.tfvars` if you like.

## 🔧 Common Errors

**`Error: No value for required variable`**

```text
The root module input variable "app_name" is not set, and has no default
value. Use a -var or -var-file command line argument to provide a value for
this variable.
```

You ran without providing `app_name` in a place where Terraform can't ask you (for example, in a CI pipeline). Pass it with `-var` or `-var-file`.

**`Error: Invalid value for input variable`**

```bash
terraform plan -var="app_name=shop" -var="server_count=two"
```

```text
Unsuitable value for var.server_count set using -var="server_count=...": a
number is required.
```

`server_count` has `type = number`, so `two` is rejected. This is why declaring a `type` is useful: it catches mistakes before anything changes.

## 🧪 Try It Yourself

1. Create a `dev.tfvars` file with `environment = "dev"` and a different `server_count`. Apply it.
2. Run `terraform apply -var-file="dev.tfvars" -var="server_count=5"`. Which value wins?
3. Add a new output called `environment` that shows `var.environment`.

Remember to run `terraform destroy` when you finish.

## ✅ What You Learned

- Variables make the same code reusable with different values.
- Variables without a default must be provided with `-var`, `-var-file`, or by typing them in.
- `type` catches wrong values early.
- Outputs show useful results, and `terraform output` reads them any time.
- Different `.tfvars` files do **not** create separate state — the same state is updated.

**Next:** [Lab 03 — State and Drift](../03-state-and-drift/README.md)
