# AutoPack Website

Marketing site and deployment infrastructure for AutoPack.

## Structure

- `site/` contains the single-file customer-facing website and Static Web Apps configuration.
- `infra/` contains Terraform for the dev and prod Azure Static Web Apps environments.
- `scripts/` contains bootstrap helpers for Terraform state, GitHub OIDC, and GitHub repository configuration.
- `.github/workflows/` contains infrastructure and site deployment workflows.

## Local preview

```bash
python3 -m http.server 4173 -d site
```

Then open `http://localhost:4173`.

## Deployment model

- `main` push deploys the site to the `dev` environment after the infrastructure exists.
- `workflow_dispatch` can target `dev` or `prod` explicitly.
- Infrastructure changes on `main` apply to `dev` automatically.
- `prod` infrastructure applies are manual through the workflow dispatch input.

## Bootstrap flow

1. Run `./scripts/setup-repository.sh` to create or connect the GitHub repository, bootstrap Terraform state, create the GitHub OIDC identity, and provision GitHub variables and secrets.
2. Commit and push the repository contents.
3. Run the `Infrastructure CI/CD` workflow for `dev`, then for `prod`.
4. Run the `App CI/CD` workflow for `dev`, then for `prod`.

## Naming

- Terraform state resource group: `rg-autopack-tfstate`
- Dev resource group: `rg-autopack-dev`
- Prod resource group: `rg-autopack-prod`
- Dev custom domain: `dev.autopack.io`
- Prod custom domain: `www.autopack.io`
