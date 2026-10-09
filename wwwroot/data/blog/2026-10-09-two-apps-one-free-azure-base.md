---
title: Two apps, one free Azure base
date: 2026-10-09
summary: How I moved my game and this site onto one shared Azure setup that costs nothing while idle, the outage I caused along the way, and what I'd do differently.
tags: Azure, .NET, AI, Job search
---

My portfolio now has two live apps: [Kings of the Card Arena](https://play.scottcoxdev.com), a card battler with a Blazor WebAssembly front end and an ASP.NET Core API, and this site. Until this week they lived in two Azure subscriptions and three regions, and each had its own container environment, log workspace and SQL server. This site was even pulling its image from a paid registry on the other side of the country.

That's fine for one app. It's waste for two, and I plan to build more. So I consolidated, again with Claude Code writing the pull requests and me reviewing, merging and running every step against Azure.

## Where it ended up

- **One shared base** in Central US: one Container Apps environment, one Log Analytics workspace with a daily cap, and one Azure SQL server that only accepts Microsoft Entra sign-ins. No passwords anywhere.
- **Each app keeps what is its own** in its own resource group, plus a free serverless database on the shared server. The free offer allows ten per subscription, so there's room to grow.
- **Images in GitHub Container Registry** instead of Azure Container Registry, which saves about $5 a month and removes a cross-region pull from every cold start.
- **Everything scales to zero.** Idle, the whole portfolio costs nothing.
- **A template for the next app:** one setup script and one workflow file give a new project its resource group, deploy sign-in, database and container app.

The game's database moved with a BACPAC export and import. Before switching over, the workflow checks that every table has the same row count and the same migrations as the original.

## What went wrong

**I took production down for about 25 minutes.** The staging and production APIs had always lived in separate environments, so they shared a container app name. Once both were in one environment, production's deploy collided with staging's app. Staging had moved first and worked perfectly, which is exactly why it couldn't catch this: the conflict only existed once both copies were in the same place. The fix gave staging its own name. The lesson is to ask, before you put two things in one place, what names they now share.

**The free database was asleep.** The first staging move failed with SQL error 40613 because the serverless database had paused itself, which is the thing that makes it free. The move now retries while the database wakes up. Nothing had changed when it failed, and the workflow put everything back where it was.

**A cleanup script worked everywhere except Windows.** On Windows the Azure CLI runs through `cmd.exe`, which misreads parentheses in an argument PowerShell passes without quotes. It failed before deleting anything, but it's a reminder that "it runs" needs to mean "it runs on the machine that will actually run it."

**Least privilege bit back.** The site's deploy identity can use the shared environment but deliberately can't read the rest of the shared resource group, so its first deploy failed while looking something up. I could have granted more access. Instead the setup script now saves the one value the deploy needs.

## Free, but not slow

Scaling to zero has a cost: the first visitor after a quiet spell waits while the game's API starts and its database resumes. Keeping one copy always running would fix that for about $20 a month per app. I chose not to.

Instead, when someone opens this site's home page, the server quietly starts the game waking in the background. By the time they've read a little and clicked through, it's usually ready. Search crawlers never trigger it, and it runs at most once every ten minutes, so a busy day can't keep the free database awake all month.

## What I'm taking from it

AI made this fast. It was a whole day of infrastructure work, not a week. But the outage was mine to own, and the fixes came from reading the actual errors, not from accepting the first suggestion. Shared infrastructure is cheaper, and it also means one mistake can reach everything. Staging, retries and checks that refuse to switch over until the data matches are what make that trade worth it.
