# 0007. Keep blog posts as Markdown files in the repository

- **Status:** Accepted
- **Date:** 2026-10-08

## Context

The site needs a blog about building software with AI tools and the job search. Posts should be easy to write, live on scottcoxdev.com so readers stay on the portfolio, and cost nothing extra to run.

## Decision

- Each post is a Markdown file in `wwwroot/data/blog/`, starting with `title`, `date`, `summary` and `tags` front matter. The file name is the URL slug.
- `BlogService`, a singleton, reads the folder once, the first time the blog is visited, renders each post to HTML with Markdig and sorts the posts newest first. Raw HTML in posts is disabled.
- `/blog` lists the posts and `/blog/{slug}` shows one. Both are static server-rendered pages, and an unknown slug returns the site's 404 page.
- A post is published by merging its pull request, which deploys the site. A post dated in the future is scheduled: it stays off the Blog page and its URL returns 404 until that day starts in US Eastern time, with no second deploy needed. In Development every post shows, so scheduled posts can be previewed locally.

## Alternatives considered

- **A hosted blog (Medium, Hashnode, Substack).** Easier to start and has built-in readers, but posts and their traffic live on someone else's site.
- **A headless CMS or a database.** Lets posts be written in a browser, but adds a service, a login and a cost for a few posts a month.

## Consequences

- Posts are versioned and reviewed like code, and the same pull request can carry a post and the change it describes.
- Writing a post needs a commit, which is fine for a developer's blog but not for a non-technical author.
- A post without a valid `date` line is skipped and logged as a warning rather than breaking the blog, so check the Blog page after merging. This follows the data-file pattern of [ADR 0003](0003-projects-as-data.md).
