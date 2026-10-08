# 0006. Show the contact email in a native pop-up with a copy button

- **Status:** Accepted
- **Date:** 2026-10-08

## Context

The Contact links were `mailto:` links. On a computer without a mail app set up, clicking one opens a "choose an app" prompt and never shows the address, so a recruiter could not see or copy it. The address also appeared in more than one place in the markup.

## Decision

- **One setting.** The address lives in `SiteInfo.Email`. The header, the home page hero and the résumé header all read it, and leaving it empty hides the Contact buttons.
- **A native pop-up.** `ContactPopover` is rendered once in `MainLayout` as an HTML `popover` element. The header's Contact button and the hero's Contact me button open it with `popovertarget`, so it works on the static pages without Blazor interactivity, and the browser handles Escape, clicking outside and focus.
- **Plain text plus a link.** The pop-up shows the address as visible text that is also a `mailto:` link, so it can be read, selected, clicked or copied.
- **A small copy script.** `wwwroot/js/contact.js` handles any button with `data-copy-text` through one delegated click listener, uses the Clipboard API, shows "Copied!" for two seconds and asks the visitor to select the text if copying is refused.

## Alternatives considered

- **Keep the `mailto:` links.** No code, but it fails for exactly the visitors who most need the address.
- **A contact form.** Visitors stay on the page, but it needs a mail-sending service, a stored secret and spam protection.
- **A Blazor interactive dialog.** Works, but the layout and résumé are static, so it would need interactivity on every page for one button.

## Consequences

- The address is in the page HTML, so scrapers can read it; spam filtering on the mailbox is the defense.
- The `popover` attribute needs a current browser (2024 or later); older browsers show the buttons but the pop-up does not open.
- Copy needs a secure context, which the site always has over HTTPS.
