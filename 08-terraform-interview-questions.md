
# Terraform Interview Questions and Answers

## 1. Terraform Fundamentals

### Q1. What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool that provisions and manages infrastructure using configuration files. It helps automate infrastructure creation and maintain consistency across environments.

### Q2. Explain the basic Terraform workflow.

The basic workflow is:

1. `terraform init` — initialize the working directory.
2. `terraform fmt` — format configuration files.
3. `terraform validate` — validate configuration syntax and consistency.
4. `terraform plan` — preview proposed changes.
5. `terraform apply` — apply the changes.

### Q3. What is the difference between a resource and a data source?

A resource manages an infrastructure object's lifecycle. A data source reads information about an existing object or retrieves information from a provider.

For example, I can use a VPC data source to look up an existing VPC and a security group resource to manage a security group in that VPC.

## 2. Terraform State and Backend

### Q4. What is Terraform state?

Terraform state maps resources managed by Terraform to real infrastructure objects. Terraform uses it to track managed resources and calculate changes.

### Q5. Why use a remote backend?

A remote backend stores state centrally so authorized engineers and CI/CD pipelines can work with the same state. An S3 backend can be combined with encryption, versioning, access controls, and state locking.

### Q6. What happens if Terraform state is lost?

The infrastructure usually continues running, but Terraform loses its record of the managed resources. I would first check for a valid backup or previous state version. If recovery is not possible, I would inventory the infrastructure and carefully import existing resources into the correct state.

### Q7. What is state locking?

State locking prevents conflicting Terraform operations from modifying the same state simultaneously. With the S3 backend, Terraform supports native locking through `use_lockfile = true`.

### Q8. What happens if a Terraform pipeline crashes while holding a lock?

I would inspect the pipeline logs and confirm that no Terraform operation is still running. If the lock is genuinely stale, I would follow the backend's supported recovery procedure. I would never unlock it blindly.

## 3. Variables, Outputs, and Modules

### Q9. Why do we use variables?

Variables allow us to parameterize Terraform configurations instead of hardcoding values. They help reuse configuration across environments with different settings.

### Q10. What are Terraform outputs?

Outputs expose selected values from resources or data sources, such as an instance ID, resource ARN, or application endpoint.

### Q11. How do you manage Dev and Prod configurations?

I use reusable Terraform configuration with environment-specific variable values and separate state for independent environments. I also use controlled deployment workflows to avoid accidentally modifying the wrong environment.

### Q12. What is a Terraform module?

A module is a collection of Terraform configuration files in a directory. Modules allow us to reuse and organize infrastructure code. For example, I can create a reusable ECS module and call it for multiple applications with different settings.

## 4. Lifecycle and Drift

### Q13. What is infrastructure drift?

Infrastructure drift occurs when actual infrastructure differs from the intended configuration or the recorded state. I use `terraform plan` to identify proposed changes and investigate the cause before applying anything.

### Q14. What does `prevent_destroy` do?

It prevents Terraform from planning destruction of a resource while the lifecycle rule remains in the applicable configuration. It is not a complete protection against every deletion path, so critical resources need additional safeguards.

### Q15. What is `create_before_destroy`?

It tells Terraform to create a replacement resource before destroying the old one when replacement is required and the infrastructure allows it.

### Q16. What is `ignore_changes`?

It instructs Terraform to ignore changes to specified resource attributes when planning updates. It should be used carefully because it can hide important drift.

## 5. Terraform in CI/CD

### Q17. How do you deploy Terraform changes through CI/CD?

I configure the pipeline to initialize Terraform, check formatting, validate the configuration, and generate a plan. The team reviews the proposed changes, and production deployments require approval before the pipeline applies the reviewed plan. I also use separate environment states and restricted cloud permissions.

### Q18. Why use `terraform plan -out=tfplan`?

It saves a plan that can be inspected and later applied using `terraform apply tfplan`. This helps ensure the pipeline applies the reviewed plan rather than generating a different one. Saved plans must be protected because they can contain sensitive information.

### Q19. Should we apply the Dev plan directly to Prod?

No. I generate a new plan using the intended production configuration and production state, review the proposed changes, and obtain the required approval.

### Q20. How do you protect Terraform secrets?

I avoid hardcoding credentials, use an approved secrets manager or short-lived workload identity, restrict access to Terraform state, and protect saved plans and pipeline artifacts.


## 6. State Management and Recovery

### Q21. What happens to the Terraform state file when we run `terraform destroy`?

`terraform destroy` destroys the resources managed by the current Terraform configuration and state, subject to dependencies and lifecycle rules. It does not normally delete the remote backend's state object or the backend bucket itself. After a successful destroy, Terraform's state records that the managed resources have been removed.

### Q22. What happens if the Terraform state file is deleted?

Deleting the state file does not automatically delete the actual infrastructure. However, Terraform loses its record of the resources it manages.

I would first check for a backup or a previous S3 object version. If recovery is not possible, I would inventory the existing infrastructure, configure the correct backend, and carefully import resources into state before running another plan.

### Q23. Where is the Terraform state file stored?

With the default local backend, Terraform generally stores state in `terraform.tfstate` in the working directory.

With a remote backend such as S3, the actual state is stored remotely at the configured bucket and key. The local `.terraform/` directory contains working data and backend metadata; it is not normally the authoritative remote state.

### Q24. How do you import an existing AWS resource into Terraform state?

First, I write Terraform configuration that describes the resource, identify its Terraform resource address and real AWS resource ID, and then import it.

Example:

```bash
terraform import aws_instance.app i-0123456789abcdef0
terraform plan
```

Import associates the existing object with the resource address in state. It does not automatically generate the full Terraform configuration. I review the plan and reconcile the configuration before making changes.

### Q25. What is the difference between `.terraform/` and `.terraform.lock.hcl`?

`.terraform/` contains local working data, such as downloaded providers, modules, and backend metadata. It is generally excluded from Git.

`.terraform.lock.hcl` records the selected provider versions and checksums. It should normally be committed to Git so team members and CI/CD pipelines can use consistent provider selections.

### Q26. What would you do if Terraform state became corrupted?

I would stop further Terraform operations against that state and investigate the failure. I would check for a valid backup or previous S3 object version and verify that it matches the infrastructure.

If recovery is not possible, I would carefully reconstruct state using supported recovery procedures and resource imports. I would then run a plan and verify the proposed changes before applying anything.

## 7. State Locking and Saved Plans

### Q27. How do you recover from a stale Terraform state lock?

First, I check pipeline logs and verify that no Terraform operation is still running. If the lock is genuinely stale, I use the backend's supported recovery procedure.

For a Terraform-managed lock that supports force unlocking:

```bash
terraform force-unlock <LOCK_ID>
```

I never unlock a state blindly because another operation may still be modifying infrastructure. Unlocking does not undo changes made before a failed operation.

### Q28. What happens if I run `terraform plan -out=tfplan` again using the same filename?

The new saved plan replaces the existing file at that path. If I need to preserve the original plan, I save it under a different filename.

Saved plans can contain sensitive information, so I protect them and never commit them to a public repository.

### Q29. What happens if a saved Terraform plan becomes stale?

Terraform may reject a saved plan if the state has changed since the plan was created. I investigate the state or infrastructure changes, generate a fresh plan, review the differences, and obtain approval again before applying.

I do not assume an old plan is still safe to execute.

## 8. Terraform Language and Resource Management

### Q30. What is the difference between `count` and `for_each`?

`count` creates multiple instances indexed numerically, such as `aws_instance.app[0]`.

`for_each` creates instances using keys from a map or set, such as `aws_instance.app["api"]`.

I prefer `for_each` when resources have meaningful identities because stable keys can reduce unintended resource replacement when the collection changes. The right choice depends on the configuration and resource identity requirements.

### Q31. Does `prevent_destroy` guarantee that a resource can never be deleted?

No. `prevent_destroy = true` blocks Terraform-planned destruction while that lifecycle rule remains in the applicable configuration. It does not protect against every deletion path, including manual deletion through the cloud provider.

For critical resources, I also use appropriate cloud-side deletion protection, backups, access controls, and change approvals.

### Q32. How do you safely manage separate Dev and Prod environments?

I use reusable Terraform modules with environment-specific configuration and separate state for independent environments. I also ensure that each pipeline uses the correct backend, variables, credentials, and permissions.

I generate and review a separate plan for each environment. I never assume a Dev plan can be applied directly to Prod.

### Q33. What is the difference between Terraform configuration and Terraform state?

Configuration describes the desired infrastructure. State records the association between Terraform resource addresses and the real objects Terraform manages, along with their recorded attributes.

Terraform uses configuration, state, and refreshed information from providers to calculate a plan.

### Q34. What is the difference between `terraform plan` and `terraform apply`?

`terraform plan` previews proposed changes without applying them to infrastructure.

`terraform apply` executes the planned changes after the appropriate review and approval. In an automated pipeline, I can save a plan with `terraform plan -out=tfplan` and apply that reviewed plan with `terraform apply tfplan`.

### Q35. How do you investigate unexpected resource replacement in a Terraform plan?

I inspect the plan to identify which attributes require replacement, then check the provider documentation and configuration to understand why. Some attributes are immutable and require a new resource.

I verify the dependencies, downtime risk, naming constraints, and environment before applying. If replacement is unexpected, I investigate the root cause and correct the configuration rather than blindly approving the change.

## Revision Strategy

- Understand the concept before memorizing the answer.
- Practise explaining each answer aloud in your own words.
- Use real project examples without revealing confidential details.
- Test practical commands in a safe sandbox before using them in production.
