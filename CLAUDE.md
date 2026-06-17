# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

Single-page PWA: cryptographically secure random number generator and coin toss.
Plain HTML/CSS/JS with Alpine.js (v3.14.9) loaded from a pinned CDN URL — **no
build step, no npm, no local dependencies, no linter.** `AGENTS.md` is a more
detailed companion to this file; consult it for finer-grained notes.

## Commands

No build system. To run: open `index.html` in a modern browser, or serve the
directory with any static file server (e.g. `python3 -m http.server`).

Statistical verification of the CSPRNG algorithms against OS randomness:
```
python3 _test_random.py
```
Runs 100k iterations for integer distribution (bounds 1–100) and 1M for coin bit
fairness. There is no JS test harness — this Python script is the only automated
test.

## Architecture

`index.html` is the entire application: CSS in a `<style>` block, markup in
`<body>`, JS in one `<script>` block at the bottom. Reactivity is driven by
**four** Alpine components registered via `Alpine.data()` inside a single
`alpine:init` listener:

| Component | `x-data` on | Owns |
|---|---|---|
| `app` | root `.app` | `activeTab`, `switchTab()`, `persistTab()` |
| `numbersPanel` | Numbers `.tab-panel` | min/max state, generation, Fisher-Yates shuffle, copy |
| `diagnostic` | `.diag-section` (inside numbers panel) | in-browser CSPRNG diagnostic |
| `coinPanel` | Coin `.tab-panel` | toss animation, H/T stats, persistence |

`activeTab` lives on `app`. `numbersPanel`, `coinPanel`, and `diagnostic` read
it **in templates** via Alpine's scope chain (parent properties are readable in
child template expressions). But `this.activeTab` is **not** accessible inside
child JS methods — `$parent` is not a valid magic property on `this` in methods.
If a child needs to react to tab changes in JS, use `$dispatch` events.

Two tabs share one `.card` layout:
- **Numbers** — min/max bounds, CSPRNG integer generation, Fisher-Yates range
  shuffle (display capped: ≤1000 shown in full, otherwise first/last 20 with
  `...`), in-browser CSPRNG diagnostic, clipboard copy.
- **Coin Toss** — CSPRNG boolean toss, animated flip, H/T stats tracker with
  session persistence.

### Persistence

All state lives under a **single localStorage key** `"random-web-prefs"` as JSON:
`{ min, max, tab, coinStats: { heads, tails } }`. Every write goes through
`updatePrefs(patch)` (shallow-merges into the stored object); every read goes
through `getPrefs()`, which returns a fully-typed, defaults-applied object from
`PREF_DEFAULTS` — callers never guard types. Adding a persistent key means
updating `PREF_DEFAULTS` and `getPrefs()`'s return shape in one place. Components
call `getPrefs()` in their `init()` and `$watch` relevant fields to auto-persist.

### CSPRNG

- `secureRandomInt(min, max)` — rejection sampling over Uint32 to eliminate
  modulo bias (`crypto.getRandomValues()`).
- `secureRandomBoolean()` — bit-0 of a single Uint8 (`=== 0` → heads).
- **`Math.random()` is used in exactly one place**, computing the *visual* coin
  flip cycle count — purely cosmetic, never the toss result. Never substitute
  `Math.random()` for either CSPRNG function.

### PWA / service worker

`sw.js` is cache-first under key `"random-web-v1"` with `ASSETS = ["/",
"/index.html", "/manifest.json", "/icon.svg"]`. Registered unconditionally on
load. **Bump the `CACHE` string in `sw.js` whenever a cached asset changes**, or
browsers serve stale content.

## Critical gotchas

- **Coin face images are giant base64 PNGs.** `--coin-heads` and `--coin-tails`
  in the `:root` CSS block are enormous single-line `url(data:image/png;base64,…)`
  values. Any tool that line-wraps, re-indents, or truncates the `:root` block will
  silently corrupt them. Never hand-edit those two lines; if they must change,
  replace the entire base64 data in one atomic operation. `_fix_coins.py` is a
  recovery tool that restores them from a known-good copy placed at
  `/tmp/orig_index.html` (manually, from git).
- **Read `index.html` before editing it.** Same root cause: the file is ~168 KB
  almost entirely because of those base64 strings. Target edits narrowly.
- **`diagnostic` must stay a direct child of `numbersPanel`** in the DOM. Its
  `runDiagnostic()` reads `this.validateBounds()`, `this.min`, `this.max`, and
  writes `this.error` via Alpine's merged scope chain. Moving `.diag-section`
  out of the `numbersPanel` subtree silently breaks those reads.
- **Don't remove either tab-visibility binding.** Panels use **both**
  `x-show="activeTab === '…'"` (Alpine, controls DOM) **and**
  `:class="{ active: … }"` (CSS hook). Both are intentional.
- **Alpine CDN version is pinned at 3.14.9** with no SRI integrity hash. Don't
  bump it without testing — Alpine minor versions can have breaking API changes.
- **No PostCSS/autoprefixer** — write CSS that works in modern browsers directly.
- `prefers-reduced-motion` is respected in both CSS (`@media`) and JS
  (`tossCoin` checks `matchMedia` and skips the flip loop). Two animation patterns
  coexist: number/shuffle pop uses `$nextTick` flag toggle to re-fire `@keyframes`;
  coin flip uses direct DOM (`classList.remove("flip")` → `void el.offsetWidth`
  reflow hack → `classList.add("flip")`). The `void el.offsetWidth` line forces
  reflow to restart the animation — do not remove it.