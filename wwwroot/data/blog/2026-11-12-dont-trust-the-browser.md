---
title: Don't trust the browser: keeping gold honest in my game
date: 2026-11-12
summary: Anyone can open the developer tools, so my card game's server plays every battle, two tabs can't spend the same gold, and every new feature has to answer one question first: how would someone farm this?
tags: .NET, Security, Game design, AI, Job search
image: /images/blog/dont-trust-the-browser.jpg
imageAlt: Title card for the post, showing the browser sending only the card it picked while the server rolls the dice and pays the gold
---

In [Kings of the Card Arena](https://play.scottcoxdev.com) you win gold by beating bosses and other players, then spend it on upgrades and wagers. Gold is the closest thing the game has to money, so it has to be hard to fake, hard to duplicate and hard to farm. This post is about how the game makes sure of that, and the question I now ask before any feature ships.

## The first bug the AI found was mine

I wrote the first version myself, then asked Claude Code to audit it before we built anything on top. Its first finding: when a boss fight ended, **the browser told the server whether you had won**. Anyone with the browser's developer tools could have sent "I won" as often as they liked, and a separate bug could pay the reward twice.

It's an easy mistake to make in a prototype, because the browser already knows the outcome. It's also the oldest rule in online games: never trust the client.

## The server plays every battle

The fix wasn't to check what the browser reported. There's nothing to check it against unless the server replays the whole fight, and at that point the server might as well play it. So it does:

- **The browser only says which card you picked.** The server rolls every die, plays the boss's move and sends back the new state.
- **Every turn is saved**, so a fight survives the server restarting or scaling to zero, and you can pick it up where you left off.
- **Rewards are paid once**, by the same request that ends the fight.
- **Your upgrades are copied into the battle when it starts.** Buying an upgrade or switching class halfway through a fight changes nothing.

Duels work the same way over SignalR, with the server holding both players' state and ending a turn after 30 seconds if someone walks away.

A bonus I didn't expect: because the dice come from an interface the server owns, tests can swap in fixed rolls. A whole boss fight in a test plays out exactly the same every time.

## Two tabs, one purse

Server-side rules aren't enough when the same player does two things at once: a double-clicked "Buy" button, a shop purchase landing just as a battle pays out, or both duellists finishing a turn as the timeout fires. If the last write wins, one change silently overwrites the other, and gold is created or lost.

Players and battles carry a version number. Every save says "update this row only if it's still the version I read". If someone else got there first, nothing is written, and the request answers with a conflict so the browser reloads. Under load testing, with hundreds of simulated players, this never produced an error. Its job is the rare case that would otherwise go unnoticed.

## How would someone farm this?

Once nobody can fake a result, the next trick is to earn rewards that aren't really earned: duel a second account you control and let it lose. Each time the game grew, this question had to be asked again:

- **Duels on the same network are practice.** Two accounts on one address can duel, but it pays nothing, moves no ratings and can't be wagered.
- **Three rewarded duels a day against the same opponent.** Later duels that day pay nothing, and any wager is refunded.
- **Quitting early doesn't count.** A duel that ends by forfeit or timeout before both players have made two moves pays nothing.
- **The Arena Bot never pays.** It's there so a lone player always has someone to duel, and a bot that never gets better would be the easiest thing in the game to farm.
- **Guests can't wager or appear on leaderboards**, so a stream of throwaway heroes can't feed a pot or crowd the rankings.
- **Challenges between friends have no wager**, so friends can't use a duel to pass gold to each other.
- **Sign-ups, guests, sign-ins and other actions are rate-limited per address**, so a script can't create an army.

None of these rules is clever on its own. What matters is that each one was decided when its feature was built, not after someone found the hole.

## What I'm taking from it

AI found the first hole in minutes, and it wrote most of the code that closed it. But it only found it because I asked for an audit before building anything else, and the farming rules came from asking "how would I cheat?" every time a new feature added a way to earn something. Speed helps. Deciding where to look is still the job.

If you missed the overview, start with [how the game was built](/blog/2026-10-15-kings-of-the-card-arena). If you're hiring a .NET developer who thinks about how things get abused before they ship, I'd like to hear from you on [LinkedIn](https://www.linkedin.com/in/scox115).
