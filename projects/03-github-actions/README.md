# Project 3 — Terraform with GitHub Actions

**Goal:** Stop running Terraform from your laptop. Let a pipeline plan every change, and apply it only after approval.

| | |
|---|---|
| ⏱️ Time | 60 minutes |
| 💰 Cost | Free — GitHub Actions is free for public repositories, and Project 2's dev VPC has no charge |
| 📖 Read first | [Terraform CI/CD](../../07-terraform-cicd.md) |
| ✔️ Complete first | [Project 1](../01-s3-remote-state/README.md) and [Project 2](../02-vpc-module-dev-prod/README.md) |

> 📝 **About the example output:** The Terraform code has been checked with `terraform fmt` and `terraform validate`, and the workflow file has been checked for valid YAML. It has not been run against a real AWS account, so treat screenshots and messages described here as examples.

## What You'll Build

```text
You open a pull request
    │
    ▼
Plan job ── fmt, validate, plan ── plan shown in the job summary
    │
You review the plan and merge
    │
    ▼
Apply job ── waits for approval ── you approve ── apply
```

**How does GitHub log in to AWS without a password?** With **OIDC**:

1. GitHub gives each workflow run a short-lived login token that says "I'm a run from repository X".
2. AWS checks the token and lets that run use an IAM role for about an hour.
3. No AWS keys are ever stored in GitHub, so there's nothing to leak.

## Files in This Project

| File | Purpose |
|---|---|
| [`oidc/main.tf`](oidc/main.tf) | Creates the AWS side: the OIDC trust and an IAM role for GitHub. You run this once from your computer. |
| [`workflow/terraform.yml`](workflow/terraform.yml) | The pipeline. You copy it into your own practice repository. |

> ℹ️ The workflow is kept in a `workflow/` folder on purpose. GitHub only runs workflows inside `.github/workflows/`, so it won't run in this learning repository.

---

## Step 1 — Create a Practice Repository

Create a new **public** repository on GitHub, for example `terraform-pipeline-practice`. (Approval rules for environments are free on public repositories.)

Copy these files from Project 2 into it, keeping the same folders:

```text
terraform-pipeline-practice/
├── modules/vpc/
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
└── environments/dev/
    ├── main.tf
    └── backend.tf
```

For `environments/dev/backend.tf`, use the file you made in Project 2, Step 3. It must point to your state bucket with the key `project-2/dev/terraform.tfstate`.

> 💡 On GitHub, **Add file → Create new file** creates folders for you when you type a path like `modules/vpc/main.tf`.

Don't add the workflow yet — AWS needs to trust GitHub first.

## Step 2 — Make Sure the State Bucket Exists

If you cleaned up Project 1, create the state bucket again:

```bash
cd projects/01-s3-remote-state/bootstrap
terraform init
terraform apply
```

Copy the `state_bucket_name` output.

## Step 3 — Let AWS Trust Your Repository

From this learning repository, on your computer:

```bash
cd projects/03-github-actions/oidc
terraform init
terraform apply \
  -var="github_repo=YOUR_GITHUB_USERNAME/terraform-pipeline-practice" \
  -var="state_bucket_name=YOUR_STATE_BUCKET_NAME"
```

(On Windows Command Prompt, write it on one line without the `\` characters.)

Read the plan, then type `yes`. ✅ **Example output:**

```text
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

role_arn = "arn:aws:iam::123456789012:role/github-actions-terraform-learning"
```

📋 **Copy your `role_arn`.**

What did this create?

| Resource | Purpose |
|---|---|
| OIDC provider | Tells AWS to trust login tokens from GitHub Actions |
| IAM role | What GitHub logs in as |
| Trust policy | **Only your repository**, and only from a pull request or the `production` environment, can use the role |
| Permissions | Manage VPCs, and read and write only the `project-2/` state files |

> 🔐 The trust policy is the most important security setting. Without the repository check, **any** GitHub repository could log in to your AWS account.

## Step 4 — Configure GitHub

In your practice repository, go to **Settings**:

**1. Add the role as a variable**

**Secrets and variables → Actions → Variables tab → New repository variable**

- Name: `AWS_ROLE_ARN`
- Value: your `role_arn`

(A role ARN isn't a password, so a variable is fine. It's useless without the trust policy.)

**2. Create an environment that needs approval**

**Environments → New environment**

- Name: `production` (exactly this — the trust policy expects it)
- Tick **Required reviewers** and add yourself
- Click **Save protection rules**

## Step 5 — Add the Workflow

In your practice repository, create the file **`.github/workflows/terraform.yml`** and paste in the contents of [`workflow/terraform.yml`](workflow/terraform.yml).

Commit it to `main`. Because it's a push to `main`, the **Apply** job starts and waits for approval. Approve it in the **Actions** tab — the first run creates the dev VPC from Project 2.

### What the workflow does

| Part | Meaning |
|---|---|
| `on: pull_request` / `push` | Runs on pull requests to `main`, and when changes land on `main` |
| `permissions: id-token: write` | Allows the OIDC login |
| `concurrency` | Never runs two Terraform jobs at once |
| **Plan** job | Runs only on pull requests: format check, init, validate, plan |
| **Apply** job | Runs only on `main`, and uses `environment: production`, so it waits for approval |
| `persist-credentials: false` | Doesn't leave a GitHub token on the runner — a small security habit |

## Step 6 — Make a Change Through a Pull Request

Let's add a second subnet to dev — the proper way.

1. In your practice repository, open `environments/dev/main.tf` and click ✏️ **Edit**.
2. Change `public_subnets` to:

   ```hcl
     public_subnets = {
       "ap-south-1a" = "10.0.1.0/24"
       "ap-south-1b" = "10.0.2.0/24"
     }
   ```

3. Choose **Create a new branch** and **Propose changes**, then **Create pull request**.

The **Plan** job starts. Open it from the pull request's **Checks** section, then open the job's **Summary**. ✅ **You should see a plan similar to:**

```text
  # module.vpc.aws_route_table_association.public["ap-south-1b"] will be created
  # module.vpc.aws_subnet.public["ap-south-1b"] will be created

Plan: 2 to add, 0 to change, 0 to destroy.
```

**Review it like a teammate would:** Is anything being destroyed? Is it the right environment? Only merge if the plan matches what you expect.

## Step 7 — Merge and Approve

1. **Merge** the pull request.
2. Go to **Actions**. The **Apply** job shows **Waiting** for review.
3. Click **Review deployments**, tick `production`, and **Approve and deploy**.

The job plans again and applies. ✅ **Example output:**

```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Check **VPC → Subnets** in the AWS Console: `dev-vpc` now has two subnets. 🎉 Your infrastructure changed without anyone running Terraform on a laptop.

## Step 8 — Clean Up

The pipeline doesn't destroy anything — and that's on purpose. Clean up from your computer:

**1. Destroy the dev VPC.** Clone your practice repository, then:

```bash
cd terraform-pipeline-practice/environments/dev
terraform init
terraform destroy
```

**2. Remove the GitHub trust and role:**

```bash
cd projects/03-github-actions/oidc
terraform destroy \
  -var="github_repo=YOUR_GITHUB_USERNAME/terraform-pipeline-practice" \
  -var="state_bucket_name=YOUR_STATE_BUCKET_NAME"
```

**3. Destroy the state bucket:** run `terraform destroy` in `projects/01-s3-remote-state/bootstrap`.

**4. In GitHub:** delete the practice repository, or at least delete the `AWS_ROLE_ARN` variable.

## 🔧 Common Errors

**`Could not assume role with OIDC` / `Not authorized to perform sts:AssumeRoleWithWebIdentity`**
The trust policy doesn't match the run. Check that `github_repo` is exactly `owner/name` (it's case-sensitive), and that the environment is named exactly `production`.

**`Credentials could not be loaded`**
The `AWS_ROLE_ARN` variable is missing or misspelled, or `permissions: id-token: write` was removed from the workflow.

**OIDC provider already exists (`EntityAlreadyExists`)**
An AWS account can only have one GitHub OIDC provider, and yours already has one. Remove the `aws_iam_openid_connect_provider` resource from `oidc/main.tf` and use the existing provider's ARN in the trust policy instead.

**`AccessDenied` during plan or apply**
The role can only manage VPCs and the `project-2/` state files. Did you change the backend `key` or add other kinds of resources?

**Check formatting fails**
Run `terraform fmt -recursive` on your computer, commit, and push again.

**Plan fails on a pull request from a fork**
GitHub doesn't give OIDC tokens to pull requests from forks. That's a security feature — someone else's code shouldn't be able to log in to your AWS account.

## 💡 Good to Know for Real Projects

- **Use two roles.** Here, one role does both plan and apply. Real teams give the plan job a **read-only** role, so a pull request can never change infrastructure.
- **Pin actions to a commit SHA** instead of a version tag like `@v7`, so the code you run can't change without you noticing.
- **The apply job plans again.** The reviewer approved the pull request plan, but the apply job makes a fresh plan before applying. If anything changed in between, the difference shows in the apply job's log. Some teams save the reviewed plan and apply exactly that file instead.

## 🧪 Try It Yourself

1. Open a pull request that breaks the formatting (add extra spaces in `main.tf`). Which step fails?
2. Open a pull request that removes the `ap-south-1b` subnet. Read the plan before merging — what will be destroyed?
3. Add a `staging` environment to the practice repository. What would you need to change in the workflow and the trust policy?

Remember to clean up when you finish.

## ✅ What You Learned

- A pipeline makes every infrastructure change visible, reviewed, and repeatable.
- OIDC lets GitHub log in to AWS with short-lived credentials — no stored keys.
- The trust policy controls exactly which repository and environment can use a role.
- Plans run on pull requests; applies run only after merge and approval.
- Separate jobs, environments, and permissions keep production safe.

**Interview practice:** Try answering [Q17–Q20](../../08-terraform-interview-questions.md) using what you did in this project.

🎓 **You've finished the Build level!** You've gone from your first `terraform apply` to a reviewed, approved, automated pipeline — the same workflow real DevOps teams use.
