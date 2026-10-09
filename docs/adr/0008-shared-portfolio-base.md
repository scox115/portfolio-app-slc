# 0008. Run the site on the shared portfolio base

- **Status:** Accepted
- **Date:** 2026-10-09

## Context

The site had an Azure subscription of its own: a Container Apps environment and a Log Analytics workspace in West US 2, an Azure Container Registry in East US, and an Azure SQL server with a free database the site never used. Kings of the Card Arena, the featured project, runs in a second subscription, and more projects are planned. Each app repeating that base means more to keep current and pay for, and the two setups had drifted apart in region and naming.

The game's repository now creates one shared base for every portfolio app: a Container Apps environment, a Log Analytics workspace and an Azure SQL server in `rg-portfolio-shared`, in Central US, in the game's subscription (its ADR 0040).

## Decision

- **The site runs in the shared Container Apps environment.** What is only the site's stays in its own resource group, `rg-portfolio-slc`: the container app. `infra/setup-azure.ps1` creates the group and an Entra app registration GitHub Actions signs in as with OIDC, with Contributor on the group and on the shared environment.
- **Images go to GitHub Container Registry** (`ghcr.io/scox115/portfolio-app-slc`), pushed with the workflow's own token. The Azure Container Registry is no longer needed.
- **The deploy creates the container app the first time and only updates its image after that,** so the custom domain bindings stay in place between deploys.
- **No database.** The site reads its projects and posts from files in the repository, so the unused free database isn't moved.
- **The domain moves once,** with `infra/move-domain.ps1`. It prints the four GoDaddy records to change (the apex `A` record and the `www` `CNAME`, each with an `asuid` `TXT` record), waits until they resolve, and binds both hostnames with free managed certificates issued in the shared environment.

## Alternatives considered

- **Keep the separate subscription.** No move, but every new project pays again for the same pieces.
- **Keep Azure Container Registry.** The Basic tier costs about $5 a month; GHCR is free for a public repository's images and is what the game already uses.
- **Describe the app in Bicep.** It would keep every setting in code, but redeploying a template that doesn't list the custom domains removes them, and listing them needs a two-pass deployment around certificate issuance. For one container app, the CLI with a create-once step is simpler.

## Consequences

- The site and the game share the environment's free monthly grant and its static IP; the apex `A` record now points at the shared environment.
- From the DNS change until the new certificates are issued, visitors may see a certificate warning for a few minutes.
- The old subscription's resources, the registry, environment, workspace and unused database, can be deleted once the site works on the shared base.
