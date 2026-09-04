# XNash Portfolio Site — "xynovim in the browser"

**Date:** 2026-09-04
**Status:** Approved design

## Purpose

A dynamic, interactive portfolio for the `XNash/XNash` special repository
page, built with Flutter web, styled and laid out like xynovim (LazyVim on
Omarchy). Showcases four projects: **heaplens**, **xynovim**,
**xyno-scholar**, **xynorash-pwsh**.

## Repo & deployment

- Flutter source lives in this repo on `main` under `site/`. The profile
  `README.md` and its assets stay untouched at the root.
- Release build: `flutter build web --release --base-href /XNash/`.
- Built output is published to a **`gh-pages` branch**; the repo's GitHub
  Pages source is switched from `main` to `gh-pages` after the first deploy.
- Local development happens in a clone at
  `~/Projects/xnash-portfolio`.

## Screen layout (LazyVim anatomy)

| Region | Widget | Behavior |
|---|---|---|
| Top | Bufferline | Tabs for open "buffers": `welcome.md`, `heaplens.rs`, `xynovim.lua`, `xyno_scholar.dart`, `xynorash.ps1`, `about.md`. Filetype icons; modified-dot on the active tab. |
| Left | Neo-tree | File explorer of `~/projects/`, one file per project plus the md pages. Collapsible; on narrow screens hidden behind a drawer toggle. |
| Center | Editor | Line-numbered, syntax-styled pane. Each project renders as a curated "source file": comment-block header (description, role, tech), highlight sections distilled from the real READMEs, repo links, and a live stats line (★ stars, last push). |
| Bottom | Lualine | Mode (NORMAL), ` main`, filetype, current theme name, line:col tracking scroll. |
| Bottom-most | Cmdline / messages | Shows pending keystrokes and hints (`Space → menu · Space f → find`); hosts `:` command input. |

## Interaction

Everything is fully mouse/touch usable; keys are flavor on top.

- `j`/`k` scroll, `gg`/`G` top/bottom.
- `H`/`L` and `[b`/`]b` previous/next buffer.
- `Space` opens a which-key popup (menu of all actions).
- `Space f` opens a Telescope-style fuzzy finder over projects; `j`/`k` or
  arrows move the selection, `Enter` opens, `Esc` closes.
- `:` opens the command line: `:q` (easter egg), `:theme <name>`.
- `Esc` dismisses any overlay.

## Theming

- Default theme: **aether** (Omarchy 4 default), plus switchable
  **catppuccin-mocha**, **vantablack**, **hackerman** — mirroring xynovim's
  Omarchy theme hot-reload.
- Palettes extracted from the upstream theme repos as Dart constants.
- Selected theme persisted in `localStorage`; falls back to aether.

## Content

- Project write-ups are **hardcoded** (curated from the real READMEs;
  editable in `data/projects.dart`).
- Stars and last-push date are fetched at page load from the public GitHub
  API (`GET /repos/XNash/<repo>`, unauthenticated). On failure or rate
  limit, baked fallback values are shown — never an error state.

## Architecture (`site/lib/`)

- `models/project.dart` — project data model.
- `data/projects.dart` — baked content for the four projects + md pages.
- `services/github_stats.dart` — API fetch with baked fallback.
- `theme/` — palette definitions (one file per theme) + theme controller
  with `localStorage` persistence.
- `keymap/dispatcher.dart` — turns raw key events into typed intents
  (scroll, buffer-switch, open-finder, …); pure logic, testable without
  widgets.
- `widgets/` — `bufferline`, `neotree`, `editor`, `statusline`,
  `whichkey`, `telescope`, `cmdline`.

## Error handling

- GitHub API: timeouts/429/offline → silent fallback to baked stats.
- `localStorage` unavailable → in-memory theme selection.
- Unknown `:` commands → vim-style message in the cmdline area
  (`E492: Not an editor command`).

## Testing

- Unit/widget tests: keymap dispatcher, fuzzy matcher, theme controller
  (persistence + fallback), stats service fallback.
- `flutter analyze` clean.
- Manual verification in Chrome before deploy.
