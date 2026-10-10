# LinkedIn posts for the blog

One post for each blog post, ready to paste. Post each one on the day its blog post goes live. LinkedIn shows the post's cover image as the link preview, so you don't need to attach a picture.

---

## 1. Building my portfolio with an AI pair programmer (live since Oct 8)

I'm looking for my next .NET role, and I've decided to do the search in public.

This week I rebuilt my portfolio site with Claude Code as a pair programmer. It wrote most of the pull requests, and I reviewed and merged every one. The site now deploys itself on every merge, signs in to Azure without stored secrets, and checks its own uptime every 30 minutes.

The interesting part is where the AI was wrong:
• It recommended a "free" Azure uptime test that was retired and replaced by a paid one.
• It built a Contact link that never showed my email address on a real Windows PC.
• It couldn't see that my headshot cut off my chin.

AI made me faster. Knowing what good looks like, testing like a user, and catching confident mistakes is still the job.

I wrote it up on my new blog: https://scottcoxdev.com/blog/2026-10-08-building-my-portfolio-with-ai

#dotnet #Blazor #Azure #AI #OpenToWork

---

## 2. Two apps, one free Azure base (live since Oct 9)

My portfolio now runs two apps on Azure, and the whole thing costs nothing while it's idle.

This week I moved my card game and my portfolio site off two subscriptions and three regions onto one shared base: one Container Apps environment, one Entra-only SQL server and a free serverless database per app. Everything scales to zero, and a template gives the next app its setup in one script.

I also took production down for about 25 minutes. Staging and production had always lived apart, so they shared a container app name. Once both were in one environment, they collided. Staging couldn't catch it, because the conflict only existed when both were in the same place.

The lesson: before you put two things in one place, ask what names they now share.

The full story, including the free database that was asleep and the script that only failed on Windows: https://scottcoxdev.com/blog/2026-10-09-two-apps-one-free-azure-base

#Azure #dotnet #DevOps #CloudComputing #OpenToWork

---

## 3. Kings of the Card Arena, built like a production service (goes live Thu, Oct 15)

I built a card game the way I'd build a production service.

Kings of the Card Arena has live duels over SignalR, real accounts with two-factor sign-in, a RabbitMQ pipeline with a transactional outbox, blue-green releases on Azure, and 480+ automated tests. It runs on free tiers and scales to zero.

The first bug the AI audit found was in my own code: the browser told the server who won, so anyone could have handed themselves gold. From then on, the server plays every battle.

My favorite bug: all the tests passed, but two real servers sharing one database could pair the same player twice. The in-memory test database never runs two things at once, so it couldn't see the race. That test now runs on a real SQL Server in CI.

You can play it as a guest in one click: https://play.scottcoxdev.com
The write-up: https://scottcoxdev.com/blog/2026-10-15-kings-of-the-card-arena

#dotnet #Blazor #SignalR #Azure #OpenToWork

---

## 4. Every merge ships: how my game deploys without breaking (goes live Thu, Oct 22)

Every merge to main in my game goes to production, with no release night.

That works because a bad build can't reach players. Staging gets every build first. Production gets the exact image staging tested, starts it with no traffic, smoke-tests it against the real database, and only then moves players over. The old version waits on standby for a one-minute rollback.

Two lessons from building it:
• A backup you haven't restored is only a hope. My game now restores its database every month and measures how long it takes. The first drill failed, and that was the point.
• A warning nobody reads is no warning. My health check reported "Degraded" for 24 deploys before I asked why.

Automation makes shipping safe. It doesn't make it unattended.

https://scottcoxdev.com/blog/2026-10-22-every-merge-ships

#DevOps #Azure #dotnet #ContinuousDelivery #OpenToWork

---

## 5. How many players can half a CPU handle? (goes live Thu, Oct 29)

How many players can half a CPU handle? I load-tested my card game to find out.

I ran k6 against the same container image production runs, capped at the same size: half a CPU and 1 GB. One replica handles about 200 players fighting at once with a median of 11 ms. At 400 it fails.

The row I learned the most from was 300. Zero errors, and it passed every threshold. But duelists waited up to 17 seconds to find an opponent. A dashboard that only counts errors would call that healthy. A player would not.

Then I made it scale out without paying for Azure SignalR Service: the duel lobby and live messages go through the SQL database the game already has. 40 players joining through two replicas at once became exactly 20 duels, with nobody paired twice.

https://scottcoxdev.com/blog/2026-10-29-how-many-players

#dotnet #SignalR #Azure #Performance #OpenToWork

---

## 6. Accounts done properly, and the gap I missed (goes live Thu, Nov 5)

My card game had password reset by email, with tests for every case. Almost nobody could use it.

The game's accounts are built like a real service's: refresh tokens that work once, two-factor with codes that can't be replayed, one-click guest play, and buttons to download or delete your data. Reset links expire, work once, and the page never reveals whether a hero exists.

Then I looked at the sign-in screen and asked: if reset needs an email, where do players give us one? Only inside a dialog no new player has a reason to open.

The fix was small: an optional email at sign-up and a gentle reminder in town. The lesson wasn't. Tests prove code does what it says. Only using the product shows whether anyone can get to it.

https://scottcoxdev.com/blog/2026-11-05-accounts-done-properly

#dotnet #Security #Identity #AI #OpenToWork
