# 0002. Build every pull request, deploy main after the build passes, and sign in to Azure with OIDC

- **Status:** Accepted
- **Date:** 2026-10-07

## Context

Changes should be checked before they reach `main`, and `main` should always be what is live. Deploys need to push to Azure Container Registry and update the Container App, and storing a long-lived Azure secret in GitHub is a risk worth avoiding.

## Decision

- **CI (`ci.yml`)** builds the Docker image on every pull request and every push to `main`. Its `build` job is a required status check on `main`, with branches kept up to date before merging and no force pushes or deletions.
- **Deploy (`deploy.yml`)** runs on `workflow_run` when CI completes successfully on `main`, or by hand from the Actions tab. It builds the image of the exact commit CI tested, tags it with the commit SHA, pushes it to the registry and points the Container App at it. A concurrency group runs one deploy at a time.
- **OIDC sign-in.** The workflow uses `azure/login` with federated credentials on an Entra app registration, trusted only for `main` and the `production` environment. GitHub stores only the client, tenant and subscription IDs, none of which is a secret.
- **No manual approval.** A merge is the approval; the deploy follows automatically.

## Alternatives considered

- **One workflow that builds and deploys.** Simpler, but pull requests and deploys would share one job, and the required check would be tied to deploy steps.
- **A service principal secret.** Works, but it expires, must be rotated and could leak.
- **A required reviewer on the production environment.** Useful on a team; for a one-person site it only added a click to every deploy.

## Consequences

- Every image in the registry maps to a commit, so a rollback is a redeploy of an earlier SHA.
- Several pull requests can be merged in a row; each green build deploys in order.
- The deploy rebuilds the image rather than reusing CI's, which costs a minute and assumes the build is reproducible.
