---
title: Building my portfolio with an AI pair programmer
date: 2026-10-08
summary: What I shipped this week with Claude Code, the mistakes it made, and why reviewing every change is still my job.
tags: AI, .NET, Blazor, Azure, Job search
---

I'm a full-stack .NET developer looking for my next role, and I've decided to do the search in public. This blog is where I'll write up what I build, how I use AI coding tools to build it, and what I learn along the way. Each post covers one real piece of work.

This week the work was the site you're reading.

## The setup

[scottcoxdev.com](https://scottcoxdev.com) is a .NET 10 Blazor Web App running in a container on Azure Container Apps. I used Claude Code as a pair programmer. It wrote most of the code as pull requests, and I reviewed and merged every one. Nothing reaches `main` without my merge and a passing build, and every merge deploys itself.

Here's what shipped:

- **A real deploy pipeline.** Every pull request builds the Docker image, and a passing build on `main` deploys to Azure. The deploy signs in to Azure with OIDC, so there's no long-lived secret stored in GitHub.
- **A custom domain** with free, auto-renewing managed certificates.
- **A homepage that gets to the point.** It has a one-line pitch, buttons to my work and résumé, a skills strip, and the bio tucked behind an "About me" button.
- **An uptime check** that loads the site every 30 minutes and opens a GitHub issue if it's down.
- **Architecture Decision Records** that explain why the site is built the way it is.

## What the AI got wrong

The useful part of this story is where I had to step in.

**It recommended a "free" service that isn't.** For uptime monitoring, the first suggestion was an Azure availability test, described as free. The free classic tests have been retired, and the ones that replaced them bill per run. We switched to a scheduled GitHub Actions workflow, which is free for a public repository and puts outage history in the issue tracker. AI tools are confident about facts that change, so pricing and product details are worth checking against current docs.

**It built a Contact link that didn't work for a real visitor.** The first version was a plain `mailto:` link. On my PC, clicking it opened a "choose an app" prompt and never showed the email address. A recruiter on a work laptop would hit the same wall. I described what I wanted, a pop-up with my address as plain text and a copy button, and the second version got it right.

**It couldn't see what I could see.** My headshot was cropped too tight and cut off my chin. Nothing in the code is wrong when that happens. You only catch it by looking at the page.

## What I'm taking from it

AI made me faster. The deploy pipeline, the uptime check and the docs would have taken me much longer alone. But speed isn't the skill. The skill is knowing what good looks like, reviewing every change, testing it like a user would, and catching the confident mistakes before they ship.

That's what I want to show employers: I can build with these tools and still own the result.

Next up, I'll write about the game in my [Project Showcase](/#projects), Kings of the Card Arena. It's a bigger project, with live PvP duels over SignalR and 34 ADRs of its own.

If you're hiring a .NET developer, I'd like to hear from you. You can find me on [LinkedIn](https://www.linkedin.com/in/scox115).
