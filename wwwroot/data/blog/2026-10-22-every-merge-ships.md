---
title: Every merge ships: how my game deploys without breaking
date: 2026-10-22
summary: Staging first, blue-green releases, one-click rollback and a backup I actually restore every month, plus the two times the pipeline told me something was wrong and I almost didn't listen.
tags: Azure, DevOps, .NET, AI, Job search
image: /images/blog/every-merge-ships.jpg
imageAlt: Title card for the post, with the release steps from merge to production listed as checks
---

In [Kings of the Card Arena](https://play.scottcoxdev.com), every merge to `main` goes to production. No release night and no checklist. If the pull request is green and I merge it, players get it about fifteen minutes later.

That only works if a bad build can't hurt anyone. This post walks through how the pipeline makes sure of that, and the two times it told me something was wrong.

## The path from merge to players

1. **CI runs on the pull request.** It builds everything and runs 480+ tests, including browser tests and concurrency tests on a real SQL Server. Each pull request also gets its own preview site, so I can click through a front-end change before merging.
2. **Staging gets it first.** Staging is a second copy of the whole game, built from the same Bicep template, with its own database, identity and secrets. The new build is deployed there and smoke-tested against real Azure SQL and Key Vault.
3. **Production gets the exact image staging tested.** Not a rebuild. What reaches players is byte for byte what passed.
4. **The new version starts with no players on it.** Azure Container Apps runs it as a new revision with no traffic. The pipeline calls that revision directly, checks its health endpoint and makes a real request through the database. Only when that passes do players move to it, all at once.
5. **The old version waits on standby.** It scales to zero, so it costs nothing, and a "Roll back the API" workflow can return to it in about a minute.

If any step fails, the run stops there. A build that can't start in Azure costs me a failed run, not an outage.

## Why all at once, and not a gradual rollout

Gradual rollouts send a slice of players to the new version first. I chose not to, and it's written down in an ADR. At the time, the duel lobby lived in each server's memory, so splitting players between two versions would have split the lobby, and two players waiting for a duel might never find each other. Testing the new revision before it gets any traffic gave me most of the safety without that problem.

The trade-off is a rule I have to follow: **database migrations must be backward compatible.** The new version updates the database while players are still on the old one, and a rollback runs old code against the new schema. So a breaking change ships in two releases: first add the new shape, then remove the old one.

## A backup you haven't restored is only a hope

Azure SQL takes backups automatically. Nobody had ever restored one, though, so nobody knew whether it worked with this setup or how long it took. Without that, the recovery time in a runbook is a guess.

So on the 1st of every month, a workflow restores the live database as it was ten minutes earlier into a temporary copy. It compares every table and the migration history with the live database, records how long the restore took, and deletes the copy. The result shows up on the game's public [status page](https://play.scottcoxdev.com/status).

The first drill failed, and that was useful. The restore itself worked, in 21.9 minutes. But GitHub's sign-in to Azure can only fetch new tokens for about five minutes, and by the time the copy was ready, the drill couldn't sign in to read it. The fix was to fetch the database token at the start. The second run passed with all 19 tables matching. Now the runbook's recovery time is a measured number, not a guess.

## When the pipeline was trying to tell me something

**A warning I'd stopped seeing.** For 24 deploys in a row, the health check reported blob storage as "Degraded". The game worked, the deploys passed, and the word sat quietly in the logs. When I finally looked, the check was asking Azure for account-level details that the API's identity isn't allowed to read, and that is how it should be. The check was wrong, not the storage. I fixed it to check the avatar container the API actually uses, and made the deploy raise a visible warning for anything less than healthy. A warning nobody reads is the same as no warning.

**A failure that wasn't real.** One day the pipeline showed "❌ Restore drill failed", for a server and a migration I didn't recognize. It turned out to be the drill's unit tests, which were writing their fake results into the real run summary. Nothing was wrong with the backups, but a false alarm in a place you trust is a real bug. The tests now clean up after themselves.

## What I'm taking from it

AI wrote most of this pipeline, and it would have taken me much longer alone. But the pipeline is only as good as the attention paid to what it reports. Both stories above were caught by a person reading output that looked fine, or looked alarming, and asking why. Automation makes shipping safe. It doesn't make it unattended.

If you missed them, I've also written about [how the game was built](/blog/2026-10-15-kings-of-the-card-arena) and [moving it onto one free Azure base](/blog/2026-10-09-two-apps-one-free-azure-base). If you're hiring a .NET developer who cares about how code gets to production, I'd like to hear from you on [LinkedIn](https://www.linkedin.com/in/scox115).
