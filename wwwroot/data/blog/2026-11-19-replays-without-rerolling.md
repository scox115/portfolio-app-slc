---
title: Replays without re-rolling the dice
date: 2026-11-19
summary: My card game now lets anyone watch a finished duel again, card by card. The interesting decision was what to save: the random seed, or what actually happened.
tags: .NET, Game design, Architecture, AI, Job search
image: /images/blog/replays-without-rerolling.jpg
imageAlt: Title card for the post, showing a duel's saved moves, each with the card played, what it did and both heroes' health afterwards
---

In [Kings of the Card Arena](https://play.scottcoxdev.com) two players duel live, one card at a time, and anyone can watch. Until recently, once a duel ended, all that was left was a line in Recent Matches: who won and how many moves it took. If you missed it, or wanted to see where a close duel turned, there was nothing to watch.

So I added replays. Every finished duel now has a page that plays it back card by card. Building it came down to one question, and the obvious answer was the wrong one.

## A duel only knew where it was

The game saved a duel's current state: both heroes' health, whether each had a shield up, and whose turn it was. After every card, that state was overwritten. That's all a live duel needs, and it's why a duel survives the server restarting or scaling to zero, as I wrote about in [Don't trust the browser](/blog/2026-11-12-dont-trust-the-browser).

A replay needs the path, not just the destination. So the duel had to start remembering how it got there.

## Save the seed, or save what happened?

Cards can miss, and an attack can be blocked by a shield, so every duel involves dice. There are two ways to play one back:

- **Save the random seed and replay the rules.** Store the starting state and the numbers the dice rolled, then run the same battle code again. It's small, and it's the approach a lot of games use.
- **Save what each card actually did.** After every card, store the result: damage dealt, health restored, blocked or not, and both heroes' health and shields afterwards.

The seed is clever, and that was the problem. It only works while the battle code gives exactly the same answer for the same numbers, forever. The first time I rebalanced a card's damage or its chance to miss, every old replay would quietly change. A duel you won on a lucky block could replay as a loss, and nothing would tell you.

Storing the results costs a small row per card, which is nothing for a duel that lasts a dozen turns. In exchange, a replay shows what happened, whatever happens to the rules later.

## The replay can't disagree with the duel

Each card played saves a move in the **same database save** as the duel itself. Either both are written or neither is. There's no moment where the duel has moved on but its replay hasn't, so a replay can never show a different ending from the one that was paid out.

I also considered keeping the log as JSON on the duel's own row. That's one table fewer, but the whole log would be rewritten after every card, and old moves couldn't be cleaned up or looked up on their own. A plain table with a row per card was simpler in every way that mattered.

## Watching at your own pace

The replay page starts playing straight away, one card every 1.2 seconds. You can:

- pause, or switch to double speed
- step back or forward one card
- jump back to the start, or skip to the result

The health bars, shields and duel log all follow whichever card is on screen. Replays are open to anyone, just like watching a duel live, because hiding a duel once it's over would protect nothing. The duel's result panel and Recent Matches link straight to the replay. Duels from before replays existed have no moves saved, so they simply show no link rather than a broken page.

## Kept as long as the duel

A replay is part of its duel's data, so it follows the same rules. Finished duels are kept for 30 days, and their moves are deleted with them. If a player deletes their account, the moves of every duel they fought go too. Deciding that up front meant it was built and tested with everything else, not bolted on after someone asked.

## What I'm taking from it

Claude Code wrote most of this feature, including the page, the tests and the database change. The part that mattered was the choice between a seed and a log, and that didn't come down to code. It came down to knowing I'll keep tuning the cards, and that a replay which silently changes is worse than no replay at all.

The decision is written down in the game's [design notes](https://github.com/scox115/gameappportfolio/blob/main/docs/adr/0038-match-replays.md), alongside the options I turned down. If you're hiring a .NET developer who thinks about what the data will need to mean a year from now, I'd like to hear from you on [LinkedIn](https://www.linkedin.com/in/scox115).
