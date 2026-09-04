# XNash Portfolio Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the "xynovim in the browser" Flutter web portfolio for the XNash special repo and deploy it to `gh-pages`.

**Architecture:** A single-page Flutter web app laid out like LazyVim: bufferline, neo-tree, editor, lualine, cmdline. Pure-logic layers (models, baked content, GitHub stats service, theme controller, key dispatcher, fuzzy matcher) are isolated from widgets and unit-tested; widgets consume them via simple `ChangeNotifier` state.

**Tech Stack:** Flutter 3.47 stable (`/opt/flutter/bin/flutter`), Dart 3; `http` package; `web` package for localStorage; `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-04-portfolio-site-design.md`

## Global Constraints

- App source lives under `site/` in the `XNash/XNash` repo; repo-root `README.md`, `xynorash_logo.png`, `devcard.png` stay untouched.
- Release build command: `flutter build web --release --base-href /XNash/` run inside `site/`.
- Flutter binary: `/opt/flutter/bin/flutter` (running as root prints a warning — ignore it).
- GitHub API calls are unauthenticated `GET https://api.github.com/repos/XNash/<repo>`; every failure path falls back to baked values, never an error UI.
- All keyboard interaction is additive: every action must also be reachable by mouse/touch.
- `flutter analyze` must be clean and `flutter test` green before every commit.
- Commit messages end with the Co-Authored-By/Claude-Session trailer used in prior commits.

---

### Task 1: Scaffold the Flutter project

**Files:**
- Create: `site/` (via `flutter create`), then trim
- Modify: `site/pubspec.yaml`, `site/web/index.html`, `site/web/manifest.json`

**Interfaces:**
- Produces: a `site/` Flutter web app named `xnash_portfolio` that builds and has a green trivial test.

- [ ] **Step 1: Create the project**

```bash
cd /home/xynorash/Projects/xnash-portfolio
/opt/flutter/bin/flutter create --platforms web --org io.github.xnash --project-name xnash_portfolio site
cd site
rm -rf test/widget_test.dart
```

- [ ] **Step 2: Set pubspec**

Replace `site/pubspec.yaml` dependencies section:

```yaml
name: xnash_portfolio
description: XNash portfolio — xynovim in the browser.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ^3.9.0

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  web: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Title + description in web/index.html**

Set `<title>XNash — Xynorash</title>`, meta description "Nash Tefison (Xynorash) — portfolio: heaplens, xynovim, xyno-scholar, xynorash-pwsh." Keep the standard Flutter bootstrap script.

- [ ] **Step 4: Smoke test**

`site/test/smoke_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke', () => expect(1 + 1, 2));
}
```

Run: `/opt/flutter/bin/flutter test` → PASS. `/opt/flutter/bin/flutter analyze` → clean.

- [ ] **Step 5: Commit** — `feat: scaffold Flutter web app under site/`

---

### Task 2: Models and baked project content

**Files:**
- Create: `site/lib/models/project.dart`, `site/lib/data/projects.dart`
- Test: `site/test/data_test.dart`

**Interfaces:**
- Produces:
  - `enum Tok { comment, keyword, string, fn, type, plain, punct, heading, link }`
  - `class Span { final String text; final Tok tok; final String? url; const Span(this.text, this.tok, {this.url}); }`
  - `class CodeLine { final List<Span> spans; const CodeLine(this.spans); }`
  - `class Buffer { final String id; final String fileName; final String icon; final String filetype; final String? repo; final int fallbackStars; final String fallbackPushed; final List<CodeLine> lines; }` (`repo == null` for md pages; `icon` is a Nerd-Font-style glyph char)
  - `const List<Buffer> kBuffers` in `data/projects.dart` — order: `welcome.md`, `heaplens.rs`, `xynovim.lua`, `xyno_scholar.dart`, `xynorash.ps1`, `about.md`.

- [ ] **Step 1: Write failing test** (`site/test/data_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xnash_portfolio/data/projects.dart';

void main() {
  test('six buffers in spec order', () {
    expect(kBuffers.map((b) => b.fileName).toList(), [
      'welcome.md', 'heaplens.rs', 'xynovim.lua',
      'xyno_scholar.dart', 'xynorash.ps1', 'about.md',
    ]);
  });
  test('project buffers carry repo + fallbacks', () {
    for (final b in kBuffers.where((b) => b.repo != null)) {
      expect(b.fallbackStars, greaterThanOrEqualTo(0));
      expect(b.fallbackPushed, isNotEmpty);
      expect(b.lines.length, greaterThan(10));
    }
  });
  test('no empty spans', () {
    for (final b in kBuffers) {
      for (final l in b.lines) {
        for (final s in l.spans) {
          expect(s.text, isNotEmpty);
        }
      }
    }
  });
}
```

Run → FAIL (files missing).

- [ ] **Step 2: Implement model** (`site/lib/models/project.dart`) exactly per Interfaces above, plus authoring helpers:

```dart
CodeLine cm(String t) => CodeLine([Span('// $t', Tok.comment)]);
CodeLine blank() => const CodeLine([Span(' ', Tok.plain)]);
CodeLine plain(String t) => CodeLine([Span(t, Tok.plain)]);
CodeLine heading(String t) => CodeLine([Span(t, Tok.heading)]);
CodeLine kv(String k, String v) =>
    CodeLine([Span(k, Tok.keyword), Span(' = ', Tok.punct), Span('"$v"', Tok.string), Span(';', Tok.punct)]);
CodeLine link(String label, String url) =>
    CodeLine([Span(label, Tok.link, url: url)]);
```

- [ ] **Step 3: Write the content** (`site/lib/data/projects.dart`)

Each buffer opens with a filetype-appropriate comment block header (`//` for .rs/.dart, `--` for .lua, `#` for .ps1/.md — adjust `cm` output per buffer by writing spans directly where needed), then curated sections. Content to bake (condense from the real READMEs, keep line width ≤ 78 chars):

- **welcome.md** — ASCII "XYNORASH" banner lines (Tok.heading), tagline "Solving problems at the edge of impossible.", one-line intro per project with its buffer name, hint lines: "Space → menu · Space f → find project · : → cmdline", "This site is built with Flutter web, styled after my xynovim setup."
- **heaplens.rs** (repo `heaplens`, fallbackStars 0, fallbackPushed "2026-07-28") — Rust workspace for heap inspection; `heaplens-protocol` crate implemented: event/frame/diff modules, frame resync + roundtrip test suite; daemon and alloc crates planned; spec-driven development (design docs in repo); link to repo.
- **xynovim.lua** (repo `xynovim`, fallbackPushed "2026-09-04") — LazyVim-based config on Omarchy/Arch; two-tier Rust diagnostics (instant rust-analyzer ~0.2s + clippy via bacon-ls ~0.6s median, before save); locally patched bacon-ls with fix filed upstream as crisidev/bacon-ls#139, verified by a 35-check headless E2E suite; Omarchy theme hot-reload; link to repo.
- **xyno_scholar.dart** (repo `xyno-scholar`, fallbackPushed "2026-08-06") — Flutter web app for interdisciplinary research-topic discovery; pure client-side, Mistral API via a stateless Cloudflare Worker CORS relay; JSON-mode + schema-in-prompt; API key in memory only; link to repo.
- **xynorash.ps1** (repo `xynorash-pwsh`, fallbackPushed "2026-06-07") — PowerShell 7 cockpit: 3-line neon prompt (identity / vitals / input), live CPU-RAM-disk-uptime vitals, git status, transient prompt, carapace completions, fastfetch, one-command install; include the README's box-drawing prompt sample as plain lines; link to repo.
- **about.md** — Nash Tefison (Xynorash); Rust · TypeScript · Dart/Flutter · PowerShell · Neovim; links: `github.com/XNash`, `daily.dev/xynorash`.

- [ ] **Step 4: Run tests** → PASS. `flutter analyze` clean.

- [ ] **Step 5: Commit** — `feat: project model and baked buffer content`

---

### Task 3: Themes and theme controller

**Files:**
- Create: `site/lib/theme/app_theme.dart`, `site/lib/theme/themes.dart`, `site/lib/theme/theme_controller.dart`
- Test: `site/test/theme_test.dart`

**Interfaces:**
- Produces:
  - `class AppTheme { final String name; final Color bg, bgDark, bgHighlight, lineNr, fg, fgDim, muted, accent, red, green, yellow, blue, purple, cyan, orange; const AppTheme({...all named required...}); }`
  - `const Map<String, AppTheme> kThemes` with keys `aether`, `catppuccin`, `vantablack`, `hackerman`
  - `class ThemeController extends ChangeNotifier { ThemeController({String? Function()? load, void Function(String)? save}); AppTheme get theme; String get name; bool setTheme(String name); }` — `setTheme` returns false for unknown names; `load`/`save` default to localStorage via `package:web` (guarded try/catch), injectable for tests.

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xnash_portfolio/theme/theme_controller.dart';
import 'package:xnash_portfolio/theme/themes.dart';

void main() {
  test('defaults to aether', () {
    expect(ThemeController(load: () => null, save: (_) {}).name, 'aether');
  });
  test('restores persisted theme, ignores garbage', () {
    expect(ThemeController(load: () => 'hackerman', save: (_) {}).name, 'hackerman');
    expect(ThemeController(load: () => 'nope', save: (_) {}).name, 'aether');
  });
  test('setTheme persists and notifies', () {
    String? saved;
    final c = ThemeController(load: () => null, save: (v) => saved = v);
    var notified = false;
    c.addListener(() => notified = true);
    expect(c.setTheme('vantablack'), isTrue);
    expect(saved, 'vantablack');
    expect(notified, isTrue);
    expect(c.setTheme('bogus'), isFalse);
  });
  test('four themes present', () {
    expect(kThemes.keys, containsAll(['aether', 'catppuccin', 'vantablack', 'hackerman']));
  });
}
```

Run → FAIL.

- [ ] **Step 2: Implement.** Palette values (from upstream repos):

| token | aether | catppuccin (mocha) | vantablack | hackerman |
|---|---|---|---|---|
| bg | `#1a1d24` | `#1e1e2e` | `#0d0d0d` | `#0B0C16` |
| bgDark | `#13161c` | `#181825` | `#0d0d0d` | `#080911` |
| bgHighlight | `#242830` | `#313244` | `#1a1a1a` | `#1a1d2b` |
| lineNr | `#4a5366` | `#6c7086` | `#505050` | `#6a6e95` |
| fg | `#a2aebb` | `#cdd6f4` | `#e0e0e0` | `#ddf7ff` |
| fgDim | `#6b7688` | `#a6adc8` | `#c8c8c8` | `#85E1FB` |
| muted | `#4a5366` | `#6c7086` | `#7a7a7a` | `#6a6e95` |
| accent | `#ad523c` | `#cba6f7` | `#c0c0c0` | `#50f872` |
| red | `#ad523c` | `#f38ba8` | `#a0a0a0` | `#50f872` |
| green | `#5e9a7e` | `#a6e3a1` | `#9a9a9a` | `#4fe88f` |
| yellow | `#d4a05a` | `#f9e2af` | `#c8c8c8` | `#7cf8d4` |
| blue | `#5a8faa` | `#89b4fa` | `#b8b8b8` | `#5ec8d4` |
| purple | `#8b6e9e` | `#cba6f7` | `#c8c8c8` | `#6fd4a8` |
| cyan | `#5b9ea0` | `#94e2d5` | `#8a8a8a` | `#7cf8f7` |
| orange | `#c47a4e` | `#fab387` | `#a0a0a0` | `#85ff9d` |

localStorage key: `xnash.theme`. Wrap all `web.window.localStorage` access in try/catch; on any throw the controller works in-memory.

- [ ] **Step 3: Run tests** → PASS. **Step 4: Commit** — `feat: four Omarchy themes with persisted controller`

---

### Task 4: GitHub stats service

**Files:**
- Create: `site/lib/services/github_stats.dart`
- Test: `site/test/github_stats_test.dart`

**Interfaces:**
- Produces:
  - `class RepoStats { final int stars; final String pushedAt; const RepoStats(this.stars, this.pushedAt); }` (`pushedAt` formatted `YYYY-MM-DD`)
  - `class GithubStats { GithubStats({http.Client? client}); Future<RepoStats> fetch(String repo, RepoStats fallback); }` — GET `https://api.github.com/repos/XNash/$repo` with 5s timeout; on non-200, timeout, or parse error returns `fallback`.

- [ ] **Step 1: Failing test** — use `http/testing.dart` `MockClient`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xnash_portfolio/services/github_stats.dart';

const fb = RepoStats(1, '2026-01-01');

void main() {
  test('parses stars and pushed date', () async {
    final svc = GithubStats(client: MockClient((req) async {
      expect(req.url.toString(), 'https://api.github.com/repos/XNash/heaplens');
      return http.Response(jsonEncode({'stargazers_count': 7, 'pushed_at': '2026-07-28T08:02:34Z'}), 200);
    }));
    final s = await svc.fetch('heaplens', fb);
    expect(s.stars, 7);
    expect(s.pushedAt, '2026-07-28');
  });
  test('falls back on 403', () async {
    final svc = GithubStats(client: MockClient((_) async => http.Response('rate limited', 403)));
    expect(await svc.fetch('heaplens', fb), fb);
  });
  test('falls back on garbage body', () async {
    final svc = GithubStats(client: MockClient((_) async => http.Response('<html>', 200)));
    expect(await svc.fetch('heaplens', fb), fb);
  });
}
```

(`RepoStats` needs `==`/`hashCode` or compare fields instead.) Run → FAIL.

- [ ] **Step 2: Implement** (catch every exception → fallback). **Step 3: tests PASS.** **Step 4: Commit** — `feat: GitHub stats service with baked fallback`

---

### Task 5: Key dispatcher and fuzzy matcher

**Files:**
- Create: `site/lib/keymap/dispatcher.dart`, `site/lib/keymap/fuzzy.dart`
- Test: `site/test/dispatcher_test.dart`, `site/test/fuzzy_test.dart`

**Interfaces:**
- Produces (`dispatcher.dart`):
  - `sealed class Intent2` with subclasses `ScrollDown, ScrollUp, ScrollTop, ScrollBottom, NextBuffer, PrevBuffer, OpenWhichKey, OpenFinder, OpenCmdline, CloseOverlay, ConfirmSelection, MoveSelectionDown, MoveSelectionUp` (all `const`, with `==` via singletons: `const ScrollDown()` etc.)
  - `enum UiMode { normal, whichkey, finder, cmdline }`
  - `class KeyDispatcher { String pending = ''; Intent2? feed(String key, UiMode mode); }` — `key` is a logical key label (`'j'`, `'k'`, `'g'`, `'G'`, `'H'`, `'L'`, `'['`, `']'`, `'b'`, `' '`, `'f'`, `':'`, `'Escape'`, `'Enter'`, `'ArrowDown'`, `'ArrowUp'`).
- Produces (`fuzzy.dart`): `List<int> fuzzyRank(String query, List<String> candidates)` — returns indices of candidates matching all query chars in order (case-insensitive), best-first (prefer earlier/denser matches); empty query → all indices in order.

Dispatch table (mode `normal`): `j`→ScrollDown, `k`→ScrollUp, `G`→ScrollBottom, `g` sets `pending='g'` and returns null, then `g` with `pending=='g'`→ScrollTop; `H`/`[`+`b`→PrevBuffer; `L`/`]`+`b`→NextBuffer; `' '` sets `pending='SPC'`→OpenWhichKey; with `pending=='SPC'`, `f`→OpenFinder; `:`→OpenCmdline. Any unmatched key clears `pending`. Modes `whichkey|finder|cmdline`: `Escape`→CloseOverlay, `Enter`→ConfirmSelection, `j`/`ArrowDown`→MoveSelectionDown (finder only for j? no — finder types into query, so in finder only arrows move selection; `j`/`k` are text), `k`/`ArrowUp`→MoveSelectionUp. In whichkey mode `f`→OpenFinder, `t` cycles theme → expose as `CycleTheme` intent (add to sealed set).

- [ ] **Step 1: Failing dispatcher test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xnash_portfolio/keymap/dispatcher.dart';

void main() {
  final d = KeyDispatcher();
  test('j scrolls down in normal', () {
    expect(d.feed('j', UiMode.normal), const ScrollDown());
  });
  test('gg goes top', () {
    expect(d.feed('g', UiMode.normal), isNull);
    expect(d.feed('g', UiMode.normal), const ScrollTop());
  });
  test('stray key clears pending', () {
    d.feed('g', UiMode.normal);
    expect(d.feed('x', UiMode.normal), isNull);
    expect(d.feed('g', UiMode.normal), isNull);
  });
  test('space then f opens finder', () {
    expect(d.feed(' ', UiMode.normal), const OpenWhichKey());
    expect(d.feed('f', UiMode.whichkey), const OpenFinder());
  });
  test('escape closes overlays', () {
    expect(d.feed('Escape', UiMode.finder), const CloseOverlay());
  });
  test('bracket b buffer nav', () {
    expect(d.feed(']', UiMode.normal), isNull);
    expect(d.feed('b', UiMode.normal), const NextBuffer());
  });
}
```

- [ ] **Step 2: Failing fuzzy test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xnash_portfolio/keymap/fuzzy.dart';

void main() {
  const names = ['welcome.md', 'heaplens.rs', 'xynovim.lua', 'xyno_scholar.dart', 'xynorash.ps1', 'about.md'];
  test('empty query returns all', () => expect(fuzzyRank('', names), [0, 1, 2, 3, 4, 5]));
  test('subsequence match', () => expect(fuzzyRank('hpl', names), [1]));
  test('xyno matches three, prefix-dense first', () {
    expect(fuzzyRank('xyno', names).toSet(), {2, 3, 4});
    expect(fuzzyRank('xyno', names).first, 2);
  });
  test('no match', () => expect(fuzzyRank('zzz', names), isEmpty));
}
```

- [ ] **Step 3: Implement both.** Fuzzy score: greedy left-to-right subsequence; score = sum of gaps + first-match index; sort ascending, stable. **Step 4: tests PASS.** **Step 5: Commit** — `feat: vim key dispatcher and fuzzy matcher`

---

### Task 6: App state

**Files:**
- Create: `site/lib/state/app_state.dart`
- Test: `site/test/app_state_test.dart`

**Interfaces:**
- Consumes: `kBuffers`, `KeyDispatcher`, `Intent2`, `UiMode`, `ThemeController`, `GithubStats`.
- Produces: `class AppState extends ChangeNotifier` with:
  - `int bufferIndex`; `Buffer get buffer`; `void openBuffer(int i)`
  - `UiMode mode`; `void openFinder() / openWhichKey() / openCmdline() / closeOverlay()`
  - `String finderQuery` + `int finderSelection` + `List<int> get finderResults` (via `fuzzyRank` over file names); `void finderType(String q)`; `void confirmFinder()`
  - `String cmdline`; `String message`; `void runCommand(String cmd)` — `:q` → `message = 'E37: No write since last change (this is a portfolio, you live here now)'`; `:theme <name>` → ThemeController.setTheme, unknown theme → `message = 'E185: Cannot find color scheme'`; anything else → `'E492: Not an editor command: <cmd>'`
  - `void handleKey(String key)` — feeds dispatcher, applies intent (scroll intents update `int scrollLines` clamped to buffer length; ScrollTop/Bottom set 0/max; buffer intents wrap around)
  - `Map<String, RepoStats> stats`; `Future<void> loadStats()` — fetches all four repos in parallel, notifies once done.

- [ ] **Step 1: Failing test** — construct `AppState(theme: ThemeController(load: () => null, save: (_) {}), stats: GithubStats(client: MockClient(...403...)))`; assert: `handleKey(']')`+`handleKey('b')` advances bufferIndex with wraparound; space→f opens finder; `finderType('xynov')` + `confirmFinder()` lands on `xynovim.lua` and mode back to normal; `runCommand('theme hackerman')` switches theme; `runCommand('wq')` sets E492 message; `loadStats()` fills all four repos with fallbacks.
- [ ] **Step 2: Implement.** **Step 3: tests PASS, analyze clean.** **Step 4: Commit** — `feat: app state wiring dispatcher, finder, cmdline, stats`

---

### Task 7: Chrome widgets (bufferline, neo-tree, statusline, cmdline)

**Files:**
- Create: `site/lib/widgets/bufferline.dart`, `site/lib/widgets/neotree.dart`, `site/lib/widgets/statusline.dart`, `site/lib/widgets/cmdline.dart`
- Test: `site/test/chrome_widgets_test.dart`

**Interfaces:**
- Consumes: `AppState`, `AppTheme`.
- Produces: `Bufferline(state, theme)`, `NeoTree(state, theme, {required void Function() onClose})`, `Statusline(state, theme)`, `CmdlineBar(state, theme)` — all stateless, re-rendered by an `AnimatedBuilder` on `AppState` in the shell (Task 9).

Visual notes (keep it authentic, all colors from `AppTheme`):
- Bufferline: horizontal row on `bgDark`; each tab = icon + filename; active tab on `bg` with `accent` underline bar and a `●` modified dot; inactive text `muted`. Tabs clickable → `openBuffer`.
- NeoTree: fixed 240px column on `bgDark`; header `  ~/projects`; rows `├─`/`└─` + icon + name; active row on `bgHighlight` with `accent` text; rows clickable. Monospace throughout (`fontFamily: 'JetBrains Mono', fallback monospace` — load via Google Fonts `<link>` in index.html for JetBrains Mono).
- Statusline: left→right: mode chip `NORMAL` (bg `accent`, dark text), ` main`, filename+icon, spacer, theme name, `☰ <scrollLine>:<col 1>`, percent. Bg `bgHighlight`.
- CmdlineBar: one line on `bg`; shows (in priority order) active `:`-input with cursor block, else `message`, else hint `Space → menu · Space f → find · : → cmd`; right-aligned pending keys from dispatcher.

- [ ] **Step 1: Failing widget test** — pump `Bufferline` + `NeoTree` + `Statusline` inside a `MaterialApp/Scaffold` with a real `AppState`; expect `find.text('xynovim.lua')` in both tree and bufferline; tap the neotree row for `xyno_scholar.dart` → `state.bufferIndex == 3`; statusline shows `NORMAL` and ` main`.
- [ ] **Step 2: Implement the four widgets.** **Step 3: tests PASS.** **Step 4: Commit** — `feat: bufferline, neo-tree, statusline, cmdline widgets`

---

### Task 8: Editor pane and overlays (which-key, telescope)

**Files:**
- Create: `site/lib/widgets/editor.dart`, `site/lib/widgets/whichkey.dart`, `site/lib/widgets/telescope.dart`
- Test: `site/test/editor_test.dart`, `site/test/overlays_test.dart`

**Interfaces:**
- Consumes: `AppState`, `AppTheme`, `Buffer`, `CodeLine`, `Tok`, `RepoStats`.
- Produces: `EditorPane(state, theme)`, `WhichKeyOverlay(state, theme)`, `TelescopeOverlay(state, theme)`.

Editor:
- `ListView.builder` with a `ScrollController` owned by `EditorPane`; `AppState.scrollLines` changes animate the controller (`state.addListener`).
- Each row: right-aligned line number (`lineNr` color, 5ch gutter) + `RichText` of spans. Tok colors: comment→`muted` italic, keyword→`purple`, string→`green`, fn→`blue`, type→`yellow`, plain→`fg`, punct→`fgDim`, heading→`accent` bold, link→`cyan` underline wrapped in gesture → `launchUrl` via `web.window.open(url, '_blank')`.
- For buffers with `repo != null`, append synthetic trailing lines: blank, then `// ★ <stars> · last push <pushedAt>` styled `Tok.comment` but with `yellow` star — read from `state.stats[repo]`, fall back to buffer fallbacks. Below it a clickable `link('→ github.com/XNash/<repo>', url)`.
- Trailing `~` rows (like vim) fill leftover viewport at `lineNr` color.

WhichKey (centered bottom sheet on `bgDark`, border `bgHighlight`): rows of `key → action`: `f → find project`, `t → cycle theme`, `e → toggle explorer`, `1..6 → goto buffer`, `q → :q`. Keys styled `accent`. Rows clickable, firing the same `AppState` methods (`openFinder`, `cycleTheme`, `toggleExplorer`, `openBuffer(i)`, `runCommand('q')` — add `cycleTheme`/`toggleExplorer`/`bool explorerOpen` to `AppState` here with a unit test in `overlays_test.dart`).

Telescope (centered modal, 560px max width): prompt line `> <query>▊`, results list (icon + name, selected row on `bgHighlight` with `accent` `>` marker), footer `<n>/<total>`. Typing is handled by the shell's key handler in finder mode (printable chars append, Backspace deletes — extend `AppState.handleKey`); rows clickable.

- [ ] **Step 1: Failing editor test** — pump `EditorPane` with state; expect first visible line text of `welcome.md`; switch to `heaplens.rs`, expect a line containing `heaplens-protocol`; expect `★ 0` fallback stats line rendered.
- [ ] **Step 2: Failing overlay test** — `state.openWhichKey()` → pump `WhichKeyOverlay`, tap `find project` row → `state.mode == UiMode.finder`; pump `TelescopeOverlay`, `state.finderType('pwsh')`, expect only `xynorash.ps1` row; `state.handleKey('Enter')` → buffer 4, mode normal.
- [ ] **Step 3: Implement.** **Step 4: tests PASS.** **Step 5: Commit** — `feat: editor pane, which-key and telescope overlays`

---

### Task 9: App shell, keyboard focus, responsive layout

**Files:**
- Create: `site/lib/main.dart`, `site/lib/app.dart`
- Modify: `site/web/index.html` (JetBrains Mono `<link>`, bg color `#1a1d24` on `<body>` to avoid white flash)
- Test: `site/test/app_test.dart`

**Interfaces:**
- Consumes: everything above.
- Produces: `void main()` → `runApp(XnashApp())`. `XnashApp` builds `MaterialApp(home: Shell())`; `Shell` owns `AppState` (+`ThemeController`, `GithubStats`), calls `state.loadStats()` in `initState`, wraps everything in `Focus`/`KeyboardListener` translating `KeyEvent`s to `state.handleKey(label)` (printable chars via `event.character`, specials mapped: Escape/Enter/Backspace/Arrows; ignore when IME/modifiers), and lays out:

```
Column(
  Bufferline,
  Expanded(Row( if (wide || explorerOpen) NeoTree, Expanded(Stack(EditorPane, overlays)) )),
  Statusline,
  CmdlineBar,
)
```

- `wide = MediaQuery.width >= 800`; on narrow screens NeoTree renders as a `Drawer`-style overlay toggled from a hamburger icon added at the left edge of the Bufferline (`state.toggleExplorer`).
- Overlays: `if (state.mode == UiMode.whichkey) WhichKeyOverlay`, `finder → TelescopeOverlay`; cmdline input renders inside `CmdlineBar`.
- Scrim behind overlays closes them on tap.

- [ ] **Step 1: Failing app test** — pump `XnashApp`; expect bufferline + statusline present; send `LogicalKeyboardKey` sequence for `]`,`b` via `tester.sendKeyEvent` → active tab becomes `heaplens.rs`; send Space, `f` → telescope visible.
- [ ] **Step 2: Implement.** **Step 3: `flutter test` all green, `flutter analyze` clean.**
- [ ] **Step 4: Manual check** — `flutter run -d web-server --web-port 8080` and eyeball at `http://localhost:8080` (or `flutter build web` + `python3 -m http.server`): themes cycle, keys work, layout at 375px width.
- [ ] **Step 5: Commit** — `feat: app shell with keyboard focus and responsive layout`

---

### Task 10: Deploy to gh-pages and switch Pages source

**Files:**
- Create: `gh-pages` branch containing `site/build/web/*` + `.nojekyll`

- [ ] **Step 1: Release build**

```bash
cd /home/xynorash/Projects/xnash-portfolio/site
/opt/flutter/bin/flutter build web --release --base-href /XNash/
```

- [ ] **Step 2: Publish build to gh-pages**

```bash
cd /home/xynorash/Projects/xnash-portfolio
git worktree add ../xnash-ghpages --orphan -b gh-pages 2>/dev/null || git worktree add ../xnash-ghpages gh-pages
cp -r site/build/web/. ../xnash-ghpages/ && touch ../xnash-ghpages/.nojekyll
cd ../xnash-ghpages && git add -A && git commit -m "deploy: portfolio site" && git push -u origin gh-pages
```

- [ ] **Step 3: Switch Pages source**

```bash
gh api -X PUT repos/XNash/XNash/pages -f 'source[branch]=gh-pages' -f 'source[path]=/'
```

- [ ] **Step 4: Push main** (`site/` source + docs) and verify `https://xnash.github.io/XNash/` serves the app (curl the page, check `<title>XNash — Xynorash</title>`; open in browser).
- [ ] **Step 5: Final commit/tidy** — ensure `site/build/` is gitignored on main.

---

## Self-review notes

- Spec coverage: layout (T7-9), interaction (T5-6, T8-9), theming (T3), content (T2), stats (T4, editor stats line T8), error handling (T3 localStorage, T4 fallback, T6 E492), deployment (T10), responsive (T9). `:q` easter egg (T6). Covered.
- Type names consistent: `Intent2`, `UiMode`, `AppState`, `AppTheme`, `Buffer`, `CodeLine`, `Span`, `Tok`, `RepoStats` used identically across tasks.
