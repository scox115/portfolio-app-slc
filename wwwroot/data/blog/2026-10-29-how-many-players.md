---
title: How many players can half a CPU handle? Load testing my game
date: 2026-10-29
summary: I load-tested my card game on a container the same size as production, found where it bends and where it breaks, then made it scale out without paying for a single extra service.
tags: .NET, SignalR, Azure, Performance, Job search
image: /images/blog/how-many-players.jpg
imageAlt: Title card for the post, with a results table showing response times rising as simulated players go from 60 to 400
---

"It works on my machine" says nothing about what happens when 200 people play at once. So before I called [Kings of the Card Arena](https://play.scottcoxdev.com) production-ready, I wanted a number: how many players can one copy of the API handle before it gets slow?

## Testing a copy, not the live game

I used [Grafana k6](https://k6.io/), which is free and open source, and pointed it at a copy of the game, never the live one. Three things ruled out testing live. The sign-up limit (three per address per hour) would stop it. Hundreds of test heroes would fill the leaderboard. And it would eat the free database's monthly allowance.

The copy had to be honest, though. The test starts the **same container image** Azure runs and limits it to the **same size as a production replica: half a CPU and 1 GB of memory**. SQL Server, RabbitMQ and blob storage run beside it, so match history flows through the message broker just as it does live. The only setting that differs is the sign-up limit, because every simulated player comes from one machine.

Each simulated player is one of two kinds:

- **Boss fighters** sign up, load the town screen, and fight the boss over the REST API, playing a card about every 1.2 seconds, over and over.
- **Duelists** connect to the SignalR hub over a WebSocket, using the same protocol as the real Blazor client, queue for a duel and play their turns.

A run passes only if fewer than 1% of requests fail, 95% of requests finish within half a second, and 95% of duel turns get from one player's screen to the other's within half a second.

## The numbers

| Players at once | Requests/s | Median | 95th percentile | Duel turn, 95th | Errors |
|---|---|---|---|---|---|
| 60 | 30 | 7 ms | 18 ms | 38 ms | 0% |
| 200 | 103 | 11 ms | 203 ms | 285 ms | 0% |
| 300 | 129 | 93 ms | 324 ms | 422 ms | 0% |
| up to 400 | 109 | 207 ms | 803 ms | 1.2 s | 0% |

One replica comfortably handles about 200 players fighting at once. At 300 it still passes, but it's straining. At 400 it fails the test.

## Zero errors isn't the same as fine

The interesting row is 300. Every request succeeded, and the 95th percentile was under the limit. By the thresholds alone, it passed.

But the median jumped from 11 ms to 93 ms, the slowest 1% of requests took over 4 seconds, and duelists waited up to **17 seconds** to be paired. Nothing was broken. Requests were queuing. A dashboard that only counted errors would have called this healthy, and a player waiting 17 seconds for an opponent would not agree.

That pattern fits the API running out of its half CPU. I want to be careful here: I didn't profile the CPU, so that's an inference from the shape of the slowdown, and the report says so. When I write up a result, I keep what I measured separate from what I concluded.

The numbers also flatter the game in one way and are harsh in another. Every simulated player is busy every second, while a real player reads the screen and browses the shop, so real traffic per player is lower. But the live game has costs the test doesn't, such as a cold start after the free database pauses.

## Scaling out without paying for it

About 200 players per replica is plenty for a portfolio game. The real problem was that there was only one replica, and three things lived in its memory: the duel lobby, which player was connected where, and the relay that publishes match events. A second replica would have split the lobby in two, and players on different replicas would never meet.

The usual fix is Azure SignalR Service, which costs about $50 a month. Instead, I moved the shared state into the SQL database the game already had:

- **The lobby is a table.** Pairing two players is two deletes in one save, with no locks. If another replica got there first, the save fails and the next player is tried.
- **Live messages for a player on another replica go through a small table** that each busy replica reads four times a second.
- **Browsers connect straight over WebSockets,** so no sticky sessions are needed and blue-green releases keep working.

The cost is up to a quarter of a second of extra delay between replicas. I measured it with two real API processes sharing one SQL Server:

- A player waiting on one replica was paired from the other within 130 to 580 ms.
- Moves crossed between replicas in 180 to 260 ms.
- 40 players joining through both replicas at once became exactly 20 duels, with nobody left waiting and nobody paired twice.
- 300 match events sent through two relays at once were each delivered exactly once, split 150 and 150.

The API now runs on up to three replicas. If the extra delay or the database load ever matters more than $50 a month, switching to Redis or Azure SignalR Service is a configuration change.

## What I'm taking from it

AI wrote the load test script and the scale-out code, and it did both quickly. What it couldn't decide for me was what "good enough" means, which numbers to trust, and when a passing result is still a bad experience. A load test is only as honest as the copy it runs against and the person reading the results.

The full report, including how to run the test yourself, is in the game's [load-testing guide](https://github.com/scox115/gameappportfolio/blob/main/docs/load-testing.md). If you're hiring a .NET developer who measures before claiming, I'd like to hear from you on [LinkedIn](https://www.linkedin.com/in/scox115).
