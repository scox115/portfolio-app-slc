# 0005. Check uptime from GitHub Actions and report outages as issues

- **Status:** Accepted
- **Date:** 2026-10-08

## Context

Nothing told anyone when the site went down; an outage would be found by a recruiter first. Azure's classic URL ping tests, which were free, are retired, and the standard availability tests that replace them bill per run.

## Decision

- A scheduled workflow (`uptime.yml`) runs every 30 minutes and can be started by hand.
- It loads `https://scottcoxdev.com` and `https://www.scottcoxdev.com`, expecting a successful response containing "Scott Cox", with three tries 20 seconds apart before calling a URL down.
- On failure it opens a "Site down" issue, or comments on the open one, so GitHub notifies the repository owner. When the site is back, it closes the issue.

## Alternatives considered

- **Application Insights standard availability tests with an alert.** Tests from several regions with richer reporting, but it costs money and needs extra Azure resources.
- **A third-party uptime service.** Free tiers exist, but it adds another account and another place to look.

## Consequences

- Free on a public repository, and the history of outages lives in the issues.
- Checks run from GitHub's runners in one region, at most every 30 minutes, and scheduled runs can start late when GitHub is busy.
- GitHub pauses scheduled workflows after 60 days with no repository activity; it can be re-enabled from the Actions tab.
