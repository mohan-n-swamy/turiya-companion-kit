---
name: defuddle
description: Extract clean markdown from web pages via the Defuddle CLI, stripping nav, ads, and clutter to save tokens. Use instead of WebFetch when the user says "read this URL", "what does this page say", "summarize this article", "fetch [link]", or pastes a URL to documentation, blog posts, news, or any standard web page. Do NOT use for URLs ending in .md — those are already markdown, use WebFetch directly.
---

# Defuddle

Use Defuddle CLI to extract clean readable content from web pages. Prefer over WebFetch for standard web pages — it removes navigation, ads, and clutter, reducing token usage.

Requires the CLI (`defuddle --version` should be ≥ 0.19.2). If missing: `npm install -g defuddle`.

## Usage

Always use `--md` for markdown output:

```bash
defuddle parse <url> --md
```

Save to file:

```bash
defuddle parse <url> --md -o content.md
```

Extract specific metadata:

```bash
defuddle parse <url> -p title
defuddle parse <url> -p description
defuddle parse <url> -p domain
```

If a host returns 403 / empty extract, retry with a browser UA:

```bash
defuddle parse <url> --md -u "Mozilla/5.0"
```

`--frontmatter` prepends YAML (title, author, source). Use it when the clip is being filed; skip it for in-chat reads.

## Output formats

| Flag | Format |
|------|--------|
| `--md` | Markdown (default choice) |
| `--json` | JSON with both HTML and markdown |
| `-f, --frontmatter` | YAML metadata prepended to markdown/HTML |
| (none) | HTML |
| `-p <name>` | Specific metadata property |
| `-u, --user-agent` | Custom UA (403 / empty-page retry) |
| `-l, --lang` | Preferred language (BCP 47) |
