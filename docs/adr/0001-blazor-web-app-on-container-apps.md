# 0001. Build the site as a Blazor Web App in a container on Azure Container Apps

- **Status:** Accepted
- **Date:** 2026-10-07

## Context

The site is a portfolio for a .NET developer, so the code behind it is part of what it shows. It needs a home page with a bio and filterable project cards, a résumé page, and room to grow. It should cost little to run and deploy the same way a production service would.

## Decision

- **Blazor Web App on .NET 10.** Pages are Razor components. The home page uses server interactivity for the tag filter; the résumé is static server rendering. Interactive pages are prerendered, so search engines and link previews get full HTML.
- **One Docker image.** The multi-stage `Dockerfile` builds and publishes the app onto the ASP.NET runtime image, running as a non-root user on port 8080.
- **Azure Container Apps.** The image runs as a Container App behind its managed HTTPS ingress. The app trusts the ingress's `X-Forwarded-For` and `X-Forwarded-Proto` headers, so redirects and generated links use `https` and the real client IP.

## Alternatives considered

- **A static site (Blazor WebAssembly or a static generator on Static Web Apps).** Cheaper and simpler, but it shows less server-side .NET, and the game already demonstrates the WebAssembly route.
- **Azure App Service.** A good fit too, but Container Apps matches how the game's API is hosted, so both projects share one deployment model.

## Consequences

- The same image runs locally in Docker and in Azure.
- Server interactivity holds a SignalR connection per visitor on interactive pages; at portfolio traffic that is negligible, and the reconnect modal covers dropped connections.
- Container Apps can scale to zero, so the first visit after a quiet spell may be slower.
