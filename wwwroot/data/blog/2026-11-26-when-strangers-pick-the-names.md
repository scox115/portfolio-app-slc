---
title: When strangers pick the names: moderation in my card game
date: 2026-11-26
summary: Hero names and portraits show up on a public leaderboard, so my card game needed name rules, an image check before anything is shown, player reports and admin tools. The hard part was not blocking the innocent.
tags: .NET, Azure, Moderation, AI, Job search
image: /images/blog/when-strangers-pick-the-names.jpg
imageAlt: Title card for the post, showing hero names checked against the rules, with Classic Knight and Badminton Ace allowed, and a disguised swear word and a fake staff name blocked
---

In [Kings of the Card Arena](https://play.scottcoxdev.com) every hero has a name and can upload a portrait. Both show up on the public leaderboard, in duels, and in other players' match history. For a while, any name of 3 to 50 characters and any picture was accepted. That's fine until the first stranger puts a slur in front of everyone.

A public game needs three things: stop the obvious cases before anyone sees them, let players flag what gets through, and let someone fix it without throwing the player out.

## Names: a short list, used carefully

The tempting fix is a big open-source list of bad words. The trouble is that big lists block ordinary names. It's known as the Scunthorpe problem, after the English town whose name contains a rude word.

So the game uses a short list and is careful about how it matches:

- **Look-alikes are folded first.** Accents are removed, `0` becomes `o`, `1` becomes `i`, `3` becomes `e`, and so on. Repeated letters are squashed, so stretching a word out or swapping in digits doesn't sneak it past.
- **Risky fragments only match as whole words.** Some short words hide inside innocent ones: "Classic" and "Title" both contain one. Those are only blocked when they stand alone, split on spaces, symbols and capital letters.
- **Nobody can pose as staff.** Names that start with or contain words like Admin, Moderator or Support are refused.

The tests that matter most aren't the ones that block. They're the ones that must pass: Classic Knight, The Therapist and Badminton Ace all have to get through. A filter that blocks real players is a bug, not extra safety.

## Portraits: checked before anyone sees them

Names can be checked with rules. Pictures can't. For those, the game uses **Azure AI Content Safety**, which rates an image for hate, sexual content, self-harm and violence. Its free tier covers 5,000 images a month, which is plenty for a portfolio game.

A few decisions shaped how it's used:

- **The check happens before the picture is saved.** Only a portrait that passes is stored and given a web address. A failed one is never anywhere another player could open it.
- **Violence gets more room than the rest.** This is a fantasy battle game, and a hero holding a sword can rate as mildly violent. Hate, sexual content and self-harm are blocked from the lowest level; violence only from the middle one. It's a single setting, easy to tighten if reports show it's too loose.
- **If it can't be checked, it doesn't go up.** When the service is down or the month's free allowance is used up, the upload is refused with a "try again later", and the player keeps their current portrait. The alternative was to let pictures through unchecked during an outage, which would quietly switch screening off. Changing a portrait can wait. Showing an offensive one can't be undone.

## Players report, admins decide

No filter catches everything. A picture of a real person, used to mock them, looks perfectly harmless to a model. So players can report a name or a portrait from the leaderboard or a duel, with a short note.

- **Reporting the same thing twice does nothing**, and each player can file 10 reports an hour.
- **The reported player is never told who reported them**, and the admin queue doesn't name reporters either, so the admin judges the content, not the people.
- **An admin can rename a hero, remove a portrait or dismiss the reports.** Each action needs a reason and goes in the audit log. A renamed player can still sign in with their old name.

I also decided against one feature that sounds sensible: hiding anything automatically once enough people report it. It's easy to abuse, because a handful of accounts could hide anyone's portrait. Every change goes through a person.

## What I'm taking from it

Claude Code wrote most of this, including the tests, the Azure setup and the admin screens. The decisions that shaped it were about people, not code: who gets the benefit of the doubt, what happens when the checker is down, and what a group of bad actors could do with a report button. Those are the questions I'd want answered before any public feature ships, whoever writes the code.

The reasoning is in the game's design notes on [moderation](https://github.com/scox115/gameappportfolio/blob/main/docs/adr/0024-moderation-and-reports.md) and [portrait screening](https://github.com/scox115/gameappportfolio/blob/main/docs/adr/0029-portrait-screening.md). If you're hiring a .NET developer who thinks about the people on the other end of a feature, I'd like to hear from you on [LinkedIn](https://www.linkedin.com/in/scox115).
