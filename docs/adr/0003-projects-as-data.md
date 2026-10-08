# 0003. Keep the project cards in a JSON data file

- **Status:** Accepted
- **Date:** 2026-10-07

## Context

The project showcase will change as new projects start and old ones are retired. When the cards were written into the page markup, each change meant editing Razor, and the tag filter list had to be kept in step by hand.

## Decision

- Projects live in `wwwroot/data/projects.json`, one object per card: title, description, type, tags and optional `gitHubUrl`, `liveUrl` and `imageUrl`.
- `ProjectService`, a singleton, reads the file once through the web root file provider and deserializes it into `Project` objects.
- The home page renders the cards and builds the tag filter from the tags the projects actually use.
- Screenshots go in `wwwroot/images/projects/` and render at 16:9 at the top of a card.

## Alternatives considered

- **A database.** More moving parts and cost for a handful of records that change a few times a year.
- **Pulling projects from the GitHub API.** Automatic, but it ties the showcase to repository metadata and to an external call on page load, and it can't hold screenshots or hand-written descriptions.

## Consequences

- Adding or removing a project is a small, reviewable data change.
- A malformed file breaks the home page, so changes still go through a pull request and CI.
- The file is read once per app start, so a change needs a deploy, which happens on merge anyway.
