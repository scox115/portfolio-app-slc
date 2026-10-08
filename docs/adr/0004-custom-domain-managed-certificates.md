# 0004. Serve scottcoxdev.com with Container Apps managed certificates

- **Status:** Accepted
- **Date:** 2026-10-07

## Context

The site was reachable only at its generated `azurecontainerapps.io` address, which is hard to remember and looks temporary on a résumé. The domain `scottcoxdev.com` is registered at GoDaddy, and `play.scottcoxdev.com` already points at the game.

## Decision

- **Apex:** an `A` record to the Container Apps environment's static IP, plus an `asuid` `TXT` record proving ownership.
- **www:** a `CNAME` to the Container App's address, plus an `asuid.www` `TXT` record.
- **Certificates:** both hostnames are bound with free managed certificates that Azure issues and renews.
- `play.scottcoxdev.com` is left pointing at the game's Static Web App.

## Alternatives considered

- **Buying or uploading a certificate.** Costs money and needs manual renewal.
- **Moving DNS to Azure DNS.** Possible later, but it adds a monthly charge and the GoDaddy records work.
- **Putting Azure Front Door in front.** Adds a CDN and a WAF, at a cost the traffic doesn't justify.

## Consequences

- Certificates renew without anyone doing anything, as long as the DNS records stay in place.
- The apex `A` record depends on the environment's IP; recreating the environment means updating DNS.
