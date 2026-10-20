# Terraform Learning Notes

**Learn Terraform step by step — with clear explanations, practical examples, and real-world DevOps scenarios.**

This repository is a beginner-friendly guide to Terraform and Infrastructure as Code (IaC). Start with the basics, practise one concept at a time, and gradually progress towards real-world AWS projects and automation.

> **New to Terraform? Start here!** You don't need to learn everything at once. Follow the learning path below at your own pace.

## 🚀 Start Here

1. Read [Terraform Fundamentals](01-terraform-fundamentals.md).
2. Do [Lab 01 — Your First Terraform Run](labs/01-first-terraform-run/README.md).
3. Keep going: read a note, then practise it in the matching lab.

**Prerequisites:** Basic command-line knowledge is helpful. The labs only need [Terraform installed](https://developer.hashicorp.com/terraform/install) — no AWS account needed until the Build projects.

## 📚 Your Learning Path

The repository has three levels. Move to the next one when you feel comfortable — there's no rush.

### 🌱 Level 1 — Learn

Understand Terraform concepts in simple language, with examples.

| Step | Topic | What You'll Learn |
|---|---|---|
| 1 | [Terraform Fundamentals](01-terraform-fundamentals.md) | Terraform, Infrastructure as Code, and core commands |
| 2 | [Resources and Data Sources](02-resources-and-data-sources.md) | Create resources and read existing infrastructure information |
| 3 | [Variables and Outputs](04-variables-and-outputs.md) | Write flexible configurations and display useful results |
| 4 | [State and Backend](03-state-and-backend.md) | State files, remote backends, and locking |
| 5 | [Terraform Modules](05-terraform-modules.md) | Build reusable infrastructure configurations |
| 6 | [Lifecycle and Drift](06-lifecycle-and-drift.md) | Resource lifecycle rules and configuration drift |
| 7 | [Terraform CI/CD](07-terraform-cicd.md) | Automate Terraform workflows safely |

### 🛠️ Level 2 — Practise

Run Terraform yourself, see what happens, and fix common errors. These labs are free and run on your own computer.

| Lab | What You'll Do | Read First |
|---|---|---|
| [Lab 01 — Your First Terraform Run](labs/01-first-terraform-run/README.md) | Run `init`, `plan`, `apply`, and `destroy` from start to finish | Step 1 |
| [Lab 02 — Variables and Outputs](labs/02-variables-and-outputs/README.md) | Reuse the same code with different values | Step 3 |
| [Lab 03 — State and Drift](labs/03-state-and-drift/README.md) | Explore state, detect drift, and see what happens when state is lost | Steps 4 and 6 |

### 🚀 Level 3 — Build

Use real AWS infrastructure in guided projects.

| Project | What You'll Build |
|---|---|
| [Project 1 — S3 Bucket with Remote State](projects/01-s3-remote-state/README.md) | A secure state bucket, then move an app's state into it |
| [Project 2 — Reusable VPC Module with Dev and Prod](projects/02-vpc-module-dev-prod/README.md) | One VPC module used for two separate environments |
| [Project 3 — Terraform with GitHub Actions](projects/03-github-actions/README.md) | A pipeline that plans on pull requests and applies after approval |

> ⚠️ Build projects create real AWS resources, which may cost money. Each project will include cost notes and clean-up steps.

## 🎯 Interview Preparation

Test your understanding with [Terraform Interview Questions](08-terraform-interview-questions.md). Try answering each one aloud before reading the answer.

## 🧭 How to Learn from This Repository

For every topic:

1. **Understand** the concept before copying the code.
2. **Explore** the example and identify what each block does.
3. **Practise** using the commands provided.
4. **Verify** the result instead of assuming it worked.
5. **Experiment** by changing one thing at a time.
6. **Clean up** resources when you finish.

The goal is not just to memorize Terraform commands. It's to understand how and why Terraform manages infrastructure.

## 🔐 Security and Cost Awareness

Infrastructure automation must be safe as well as functional.

- Never commit cloud credentials, passwords, tokens, or private keys.
- Do not commit Terraform state files or saved plan files; they may contain sensitive information.
- Review `terraform plan` before applying changes.
- Use least-privilege permissions and short-lived credentials where possible.
- Review AWS pricing before provisioning resources.
- Clean up test infrastructure when finished.
- Never destroy shared or production infrastructure without understanding the impact and having authorization.

## 🤝 Contributing

This repository aims to help anyone learning Terraform, from beginners to working DevOps engineers.

Contributions are welcome! You can help by:

- Improving explanations
- Fixing mistakes
- Adding tested examples
- Sharing useful diagrams
- Documenting common errors and solutions
- Creating beginner-friendly exercises

Please explain your changes clearly and test code examples before describing them as working.

## 📖 Official Resources

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Tutorials](https://developer.hashicorp.com/terraform/tutorials)
- [Terraform Registry](https://registry.terraform.io/)

## 👨‍💻 About This Repository

A growing, practical learning resource for Terraform, AWS, Infrastructure as Code, and DevOps automation.

The focus is simple: **learn one concept, practise it, understand the result, and build towards real-world skills.**

If you find this repository useful, consider giving it a ⭐ and contributing improvements that help other learners.
