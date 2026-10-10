---
title: Accounts done properly, and the gap I missed
date: 2026-11-05
summary: Two-factor sign-in, one-click guest play, a real "delete my data" button and password reset by email, plus the moment I noticed the reset feature worked perfectly and almost nobody could use it.
tags: .NET, Security, Identity, AI, Job search
image: /images/blog/accounts-done-properly.jpg
imageAlt: Title card for the post, listing the game's account features as checks, ending with a question about where to add an email
---

A game is a nice excuse to build the parts of a real service nobody sees in a demo. In [Kings of the Card Arena](https://play.scottcoxdev.com) a hero holds gold, upgrades and a public rating, so the account behind it has to be treated like any other account that matters. This post covers how sign-in works, what the game does with your data, and a gap in password reset that every test passed straight over.

## Signing in

The game uses ASP.NET Core Identity for users and password hashes, with short-lived tokens:

- **Access tokens live 15 minutes** and are kept only in the app's memory, never in browser storage.
- **Refresh tokens are used once.** Each refresh issues a new one and retires the old. If an old one is ever used again, that's the sign of a stolen token, and every session for that account is revoked.
- **One browser per hero.** Signing in somewhere new signs the old browser out, and it's told instantly.
- **Guessing is slow.** Five wrong passwords lock the account for five minutes, and sign-ups and sign-ins are rate-limited per address.

## Two-factor, for anyone who wants it

Passwords get reused and leaked, so players can turn on a second step with any authenticator app. A few details I cared about:

- **A code works once.** The standard allows a code to be accepted for its whole 30-second window. The game remembers the last one used, so a code someone watched you type can't be replayed.
- **Ten recovery codes**, shown once and stored only as hashes, in case the phone is lost.
- **Turning it off needs both the password and a code**, so neither a stolen password nor a stolen phone is enough on its own.
- **No codes by email or SMS.** Email is already the password reset channel. If it were also the second step, one inbox would be enough to take an account.

## One click to play

Someone clicking through from my CV wants to see the game working in seconds, not fill in a form. So "Play as a guest" starts a hero with a made-up name and no password. Guests can fight the boss, shop and duel, but can't wager gold or appear on leaderboards, so nobody can farm a fleet of throwaway heroes. If they like it, one form keeps the hero under their own name and password, with all its progress. Abandoned guests are deleted after about a week.

## Your data, on request

"Your account and data" in town has two buttons. **Download my data** returns a JSON file of everything the game stores about you, minus the hashes only the server can use. **Delete my hero forever** asks for your password and erases the account and everything tied to it in one transaction, so a failure leaves it whole rather than half-deleted. Opponents keep their record of duels with you, with your name replaced by "A retired hero".

## Forgot your password?

Until recently, a forgotten password meant someone editing the database. Now a player can add a recovery email and get a reset link:

- **The address only counts once it's confirmed** by clicking a link sent to it.
- **Links work once and expire**: an hour for a reset, a day for a confirmation. The database stores only a hash of each link, never the link itself.
- **The page never says whether a hero exists.** "Forgot your password?" gives the same answer for every name, so it can't be used to find accounts.
- **A reset signs you out everywhere**, in case the reason for it was someone else knowing your old password.

## The gap

Here's the part I want to be honest about. Password reset shipped with tests for every case above, and they all passed. Then I looked at the sign-in screen and asked a simple question: "Forgot password only works if you entered an email, but we never ask for one, right?"

Right. The only place to add an address was inside the account dialog, which a new player has no reason to open. The feature worked perfectly, and almost nobody could use it.

The fix was small. Creating a hero now has an optional "Recovery email" field that says what it's for. Players without one see a short note in town with **Add one** and **Not now**. "Not now" brings it back a week later, and a "Don't remind me again" box makes it go away for good. It's still optional, because the whole point of guest play is that nobody has to hand over anything to try the game.

## What I'm taking from it

AI wrote most of this code, and it did the security details well, from single-use codes to not leaking which heroes exist. What it didn't do was step back and ask whether a player would ever reach the feature. Tests prove the code does what it says. Only using the product shows whether anyone can get to it.

If you'd like to see more of how the game was built, start with [the overview](/blog/2026-10-15-kings-of-the-card-arena). If you're hiring a .NET developer who tests like a user as well as a developer, I'd like to hear from you on [LinkedIn](https://www.linkedin.com/in/scox115).
