
# Terraform in CI/CD Pipelines

## 1. Why Use Terraform in CI/CD?

CI/CD pipelines automate the process of validating, reviewing, and applying infrastructure changes.

Instead of engineers manually running Terraform commands on their laptops, a pipeline can execute them consistently with controlled permissions.

Benefits:
- Repeatable infrastructure deployments.
- Automated configuration validation.
- Reviewable infrastructure changes.
- Approval gates for production.
- Better auditability through Git history and pipeline logs.

## 2. Typical Terraform CI/CD Workflow

1. Developer updates Terraform configuration.
2. Developer pushes the changes to Git.
3. Pipeline checks out the code.
4. Pipeline initializes Terraform.
5. Pipeline validates the configuration.
6. Pipeline generates a Terraform plan.
7. Team reviews the plan.
8. Authorized reviewer approves the production deployment.
9. Pipeline applies the reviewed plan.
10. Pipeline records the result.

## 3. Common Terraform Commands in CI/CD

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Explanation:

- `terraform init`: Initializes providers, modules, and the configured backend.
- `terraform fmt -check -recursive`: Checks formatting without modifying files.
- `terraform validate`: Checks configuration syntax and internal consistency.
- `terraform plan -out=tfplan`: Creates a saved plan for review and later application.
- `terraform apply tfplan`: Applies the saved plan rather than generating a new one.

Note: `terraform validate` does not replace a plan against the intended environment.

## 4. Why Use a Saved Plan?

A saved plan lets the pipeline apply the changes that were reviewed instead of generating a different plan at apply time.

Example:

```bash
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
```

The pipeline should review the plan and obtain the required approval before applying it.

Saved plans can contain sensitive information. Protect them as pipeline artifacts, restrict access, and avoid committing them to Git.

A saved plan can become stale if the state or infrastructure changes. Terraform may reject it, in which case the pipeline should generate and review a fresh plan.

## 5. Handling Dev and Prod

For a multi-environment deployment:

- Use separate state for Dev and Prod.
- Use the correct variable files and environment configuration.
- Apply changes to Dev first when appropriate.
- Review and test the results.
- Generate a new plan against Prod's own configuration and state.
- Require approval before production changes.

Important: Do not blindly apply the Dev plan to Prod. Generate the production plan for the intended production configuration.

## 6. Authentication and Security

- Prefer short-lived credentials through OIDC or an equivalent workload identity mechanism when supported.
- Grant the pipeline only the permissions it needs.
- Never hardcode AWS access keys in Terraform files.
- Store secrets in an approved secrets manager.
- Protect state files and saved plan artifacts.
- Restrict who can approve production deployments.

## 7. Real-World DevOps Example

Suppose we need to change the CPU allocation of an ECS service.

I update the Terraform configuration and push the change to Git. The CI/CD pipeline initializes Terraform, validates the configuration, and generates a plan.

I review the proposed ECS changes. After the required approval, the pipeline applies the reviewed plan using the appropriate AWS identity and production state.

I then verify the deployment and check application health.

## 8. Common Mistakes

- Applying infrastructure changes without reviewing the plan.
- Using the wrong backend or environment variables.
- Sharing saved plans publicly.
- Giving the pipeline excessive AWS permissions.
- Applying a stale plan.
- Allowing multiple uncontrolled pipelines to modify the same state.

## 9. Interview Q&A

**Q: How do you deploy Terraform changes through a CI/CD pipeline?**

A: I integrate Terraform with the CI/CD pipeline so that every infrastructure change is validated and planned before deployment. The pipeline runs initialization, formatting checks, validation, and plan generation. The team reviews the proposed changes, and production requires approval before the pipeline applies the reviewed plan. I also use separate environment states and restricted cloud permissions to make deployments safer.
