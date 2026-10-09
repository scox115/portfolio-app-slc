# 0009. Wake each project's backend when someone opens the home page

- **Status:** Accepted
- **Date:** 2026-10-09

## Context

The projects this site links to scale to zero to stay free. Kings of the Card Arena's API stops when idle and its free database pauses after an hour, so the first visitor after a quiet spell waits while both start. Most visitors land here first and read for a while before clicking through, which is time the backend could spend starting.

## Decision

- A project in [`projects.json`](../../wwwroot/data/projects.json) can have a `wake` entry: either a `url` to call (a health check), or, for a Blazor WebAssembly front end, a `settingsUrl` pointing at its published appsettings file. The API address is read from that file's `ApiBaseUrl` and `path` (default `/health/ready`) is called on it, so the wake follows the API when its address changes.
- When the home page becomes interactive, the server starts those calls without waiting for them. Crawlers never open the live connection, so they don't wake anything.
- Each project is woken at most once every 10 minutes, whatever the traffic. The settings file is read at most once an hour.

## Alternatives considered

- **Call the health checks from the visitor's browser.** Needs each API to allow this site's origin, and every visitor would make the call.
- **A scheduled ping that keeps everything awake.** Holds the free database awake all month and uses up its allowance.
- **Keep one copy of each API always running.** About $20 a month per app; left as a per-app switch for weeks when a project is being shown.

## Consequences

- A visitor who reads the home page for a few seconds usually finds the game ready when they open it.
- Each wake uses a little of the game's free database and Container Apps allowances. The 10-minute limit bounds that at roughly six wakes an hour, and only while real people are visiting.
- A project with nothing to wake simply leaves `wake` out.
