# Lab 03 — State and Drift

**Goal:** See what the state file is, what happens when someone changes things outside Terraform, and what happens when state is lost.

| | |
|---|---|
| ⏱️ Time | 20 minutes |
| 💰 Cost | Free — no cloud account needed |
| 📖 Read first | [State and Backend](../../03-state-and-backend.md) and [Lifecycle and Drift](../../06-lifecycle-and-drift.md) |
| ✔️ Complete first | [Lab 01](../01-first-terraform-run/README.md) |

## Step 1 — Create Something

From the Lab 02 folder, move into this lab's folder:

```bash
cd ../03-state-and-drift
```

[`main.tf`](main.tf) creates one file, `notes.txt`:

```hcl
resource "local_file" "notes" {
  filename = "${path.module}/notes.txt"
  content  = "This file is managed by Terraform.\n"
}
```

Create it:

```bash
terraform init
terraform apply
```

Type `yes` when asked.

## Step 2 — Look at the State

After `apply`, a file called `terraform.tfstate` appeared. List what it records:

```bash
terraform state list
```

✅ **What you should see:**

```text
local_file.notes
```

Show the details Terraform remembers about that resource:

```bash
terraform state show local_file.notes
```

✅ **What you should see:**

```text
# local_file.notes:
resource "local_file" "notes" {
    content              = <<-EOT
        This file is managed by Terraform.
    EOT
    content_md5          = "5f9a36542b953ebb2b699f889a7d45bf"
    filename             = "./notes.txt"
    ...
}
```

The state file is how Terraform knows that `local_file.notes` in your code is the real `notes.txt` on disk. You can open `terraform.tfstate` in an editor to look — it's JSON — but **never edit it by hand**.

> ⚠️ With real cloud resources, state can contain passwords, keys, and other secrets. That's why it must never be committed to Git.

## Step 3 — Change Something Outside Terraform (Drift)

Pretend a teammate edited the file by hand instead of changing the Terraform code:

```bash
echo "Someone edited this by hand." > notes.txt
```

The real file no longer matches what Terraform expects. This is called **drift**.

Ask Terraform what it sees, without changing anything:

```bash
terraform plan -refresh-only
```

✅ **What you should see:**

```text
Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply" which may have affected this plan:

  # local_file.notes has been deleted
  - resource "local_file" "notes" {
      ...
```

`-refresh-only` compares your state with the real world and reports differences. It's a safe way to **detect** drift.

The `local` provider treats a file whose content changed as "deleted", because it no longer matches. Cloud providers like AWS usually show the exact attribute that changed instead, such as an instance type.

Now run a normal plan:

```bash
terraform plan
```

✅ **What you should see:**

```text
  # local_file.notes will be created

Plan: 1 to add, 0 to change, 0 to destroy.
```

Terraform plans to put the file back the way the code describes. Run `terraform apply`, type `yes`, and check:

```bash
cat notes.txt
```

```text
This file is managed by Terraform.
```

The hand-made change has been **overwritten**. In a real project, before applying, you'd first ask *why* someone changed it — maybe the change was needed and the code should be updated instead.

## Step 4 — Delete Something Outside Terraform

```bash
rm notes.txt
terraform plan
```

(On Windows Command Prompt, use `del notes.txt`.)

✅ **What you should see:**

```text
  # local_file.notes will be created

Plan: 1 to add, 0 to change, 0 to destroy.
```

Terraform notices the file is missing and plans to recreate it. Run `terraform apply` to bring it back.

## Step 5 — Lose the State

Now let's see what happens when the state file disappears. Rename it (don't delete it — we'll put it back):

```bash
mv terraform.tfstate saved.tfstate
```

(On Windows Command Prompt, use `ren terraform.tfstate saved.tfstate`.)

`notes.txt` still exists. But ask Terraform what it manages:

```bash
terraform state list
```

✅ **What you should see:**

```text
No state file was found!
```

And plan:

```bash
terraform plan
```

✅ **What you should see:**

```text
  # local_file.notes will be created

Plan: 1 to add, 0 to change, 0 to destroy.
```

**The file is still there, but Terraform has forgotten about it.** It thinks it needs to create something that already exists.

With a text file, that just overwrites it. With AWS, it could try to create a *duplicate* server, or fail with a "resource already exists" error — while the original resource keeps running (and costing money) with nobody managing it.

**Do not apply.** Put the state back instead:

```bash
mv saved.tfstate terraform.tfstate
terraform plan
```

(On Windows Command Prompt, use `ren saved.tfstate terraform.tfstate`.)

✅ **What you should see:**

```text
No changes. Your infrastructure matches the configuration.
```

Everything is back to normal. This is why real projects keep state in a safe, backed-up remote location, such as an S3 bucket with versioning turned on.

## Step 6 — Clean Up

```bash
terraform destroy
```

Type `yes`. `notes.txt` is removed.

## 🔧 Common Errors

**`No state file was found!`**
You're in the wrong folder, or no `apply` has run yet. Check you're in the folder that contains `terraform.tfstate`.

**Terraform wants to create resources that already exist**
The state is missing or you're using the wrong state. Stop and check before applying. Restore the state from a backup if you can.

## 🧪 Try It Yourself

1. Change `content` in `main.tf` and run `terraform plan -refresh-only`. Does it show your code change? (Hint: `-refresh-only` only looks for changes made *outside* Terraform.)
2. After `apply`, look for a file called `terraform.tfstate.backup`. When does it change?

Remember to run `terraform destroy` when you finish.

## ✅ What You Learned

- The state file links your code to real resources.
- `terraform state list` and `terraform state show` let you inspect state safely.
- **Drift** is when real resources change outside Terraform. `terraform plan -refresh-only` detects it.
- A normal `apply` overwrites drift — find out why it happened first.
- If state is lost, the resources still exist, but Terraform forgets them. Protect and back up your state.

**Next:** [Project 1 — S3 Bucket with Remote State](../../projects/01-s3-remote-state/README.md) uses these ideas with real AWS resources.
