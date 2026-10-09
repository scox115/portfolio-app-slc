---
title: Kings of the Card Arena, built like a production service
date: 2026-10-15
summary: How a small card game became a live, tested, scale-to-zero .NET and Azure service, the bugs that only showed up in the real world, and what I learned about reviewing an AI's work.
tags: .NET, Blazor, SignalR, Azure, AI, Job search
image: /images/blog/kings-of-the-card-arena.jpg
imageAlt: Title card for the post, with a screenshot of two heroes in a live duel in Kings of the Card Arena
---

In my [first post](/blog/2026-10-08-building-my-portfolio-with-ai) I promised to write about the bigger project in my [Project Showcase](/#projects). This is that post.

[Kings of the Card Arena](https://play.scottcoxdev.com) is a turn-based card battler. You pick a hero class, fight bosses for gold, spend it on card upgrades, and duel other players live. One click lets you play as a guest, and if nobody else is online, the Arena Bot will duel you.

The game is small on purpose. I wanted something I could finish that is still hard in the ways real services are hard: players acting at the same time, gold that must never be lost or duplicated, live connections, and a public deployment that has to stay up and stay cheap.

## How it started

I wrote the first version myself over a couple of days: a .NET solution with a domain project, a data layer, an API and a Blazor WebAssembly client. Then I brought in Claude Code and asked it to audit what I had before building anything on top.

The first finding was in my own code. The browser told the server whether you had won a boss fight, and the reward could be paid twice. Anyone with the browser's developer tools could have handed themselves gold. That set the rule for everything after it: **the server plays every battle.** The client only says which card you picked. The server rolls every die, plays the boss's move and pays rewards once, and optimistic concurrency means two browser tabs can't spend the same gold twice.

From there we worked through a production-readiness roadmap, with me picking what came next: CI, real sign-in, health checks, Azure, tests, docs, and then the game features.

## What's in it now

- **Live duels over SignalR**, with 30-second turns, gold wagers and an Elo rating. You can spectate a duel in progress, replay any finished one card by card, and challenge friends who are online.
- **Clean Architecture**, with the battle rules in a domain project that has no framework references. That made the rules easy to test, and it let a throwaway simulator run the real production code.
- **Real accounts:** ASP.NET Core Identity, short-lived JWTs with rotating refresh tokens, optional two-factor sign-in, password reset by email, and an export-and-delete-my-data page.
- **A RabbitMQ pipeline** for match history and daily stats, with a transactional outbox so no event is lost. The game keeps working if the broker is down.
- **Azure on free tiers:** Container Apps that scale to zero, a free serverless Azure SQL database, Static Web Apps, and no stored passwords anywhere. GitHub signs in with OIDC, and the API reaches SQL, Storage and Key Vault as a managed identity.
- **A release pipeline** that deploys every merge to a full staging copy first, then promotes the exact image staging tested. Production uses blue-green releases with one-click rollback, and every pull request gets its own preview site.
- **Operations:** a public [status page](https://play.scottcoxdev.com/status), OpenTelemetry to Application Insights, an ops dashboard and email alerts, and a monthly drill that restores the database from backup to prove the backups work.
- **480+ automated tests**, from domain unit tests to Playwright browser tests with accessibility checks to k6 load tests. One replica handles about 200 players fighting at once on half a CPU.
- **40 Architecture Decision Records** that explain why it's built this way and what each choice gave up.

## The bugs that taught me the most

**The race the tests couldn't see.** To run more than one copy of the API, the duel lobby moved out of memory and into the database. All the tests passed. Then I ran two real API processes against one SQL Server, and a duel request failed. The lobby checked whether a player was still waiting and then loaded them in a second query, and the other copy could pair that player in the gap. The tests missed it because the in-memory test database never runs two things at once. The fix was one query instead of two. The lasting change was running that 40-player lobby test on a real SQL Server in CI, where it fails three runs out of three with the fix undone.

**Balance by feel didn't work.** The first class bonuses I tried looked reasonable on paper. A simulation of 20,000 fights per matchup showed some duels at 65/35. Now every balance change comes with numbers: smaller bonuses keep every class matchup between 46% and 52%.

**A scripted edit that hit twice.** One change edited the deploy workflow with a find-and-replace that matched two lines instead of one. CI passed, but the next production deploy failed. The fix was quick, and the lesson stuck: after a scripted edit, read the diff as carefully as hand-written code.

**Azure said no.** Azure wasn't accepting new SQL servers in the region I picked, so for a while the database ran in Central US while the API ran in East US 2, adding a cross-region hop to every query. Moving everything onto one shared Azure base put them back in the same region.

## What only playing it found

The automated tests catch a lot, but some bugs only show up when a person plays.

- The attack buttons ignored my clicks during the boss's turn.
- Chrome's password autofill sent a keypress with no key and crashed the sign-in form.
- Double-tapping Play Game signed me in and then straight back out, because the second sign-in replaced the first session.

I found each one by playing, and each fix shipped with a browser test so it can't come back.

I also asked whether Razor files that mix HTML, inline styles and C# are how larger teams write Blazor. They aren't, so we cut the inline styles from 333 to 22 by moving them into per-component stylesheets, split the biggest pages into components with code-behind files, and wrote down the convention in an ADR. A check that compared the computed style of every element on 33 screens before and after made sure nothing looked different.

## What I'm taking from it

The AI wrote most of the code, and it was fast: the game went from my prototype to a live, tested service in under a week. But speed isn't the part I'd hire for. The valuable work was deciding what to build, insisting on proof before trusting a change, and testing the game the way a player would. The best bugs in this post were found by running the real thing, not by reading code that looked right.

I've also written about moving this site and the game onto one free Azure setup in [Two apps, one free Azure base](/blog/2026-10-09-two-apps-one-free-azure-base).

You can [play the game](https://play.scottcoxdev.com), and if you're hiring a .NET developer, I'd like to hear from you on [LinkedIn](https://www.linkedin.com/in/scox115).
