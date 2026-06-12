# AGENTS.md — random-web

## Project Status

Single-page web app. Plain HTML/CSS/JS — no framework, no build step, no
dependencies beyond a browser.

## Architecture

`index.html` is the entire application. It embeds all CSS in a `<style>` block
and all JavaScript in a `<script>` block at the bottom of `<body>`. The app
has two tabs sharing one card layout:

- **Numbers** — configurable min/max bounds, CSPRNG-backed integer generation
- **Coin Toss** — single-bit CSPRNG toss with H/T display, stats tracker

Data flow:
1. User sets bounds → persisted to `localStorage` under key `random-web-prefs`
2. `crypto.getRandomValues()` feeds both `secureRandomInt()` (rejection-sampled
   Uint32) and `secureRandomBoolean()` (bit-0 of Uint8)
3. Results display with CSS animations; bounds persist across sessions

## Key Files & Directories

- `index.html` — the app: structure, styles, and logic in one file
- `_test_random.py` — statistical verification of CSPRNG algorithms (Python)
- `.gitignore` — ignores `.codewhale/*` (except `constitution.json`) and
  `.deepseek/`
- `.codewhale/` — CodeWhale project configuration

## Build / Test / Lint

No build system. To run: open `index.html` in any modern browser.

- **Statistical test**: `python3 _test_random.py`
  Validates the CSPRNG number generator (uniform distribution) and coin toss
  (bit-level fairness) with 100k–1M iterations each.

## Git Workflow

No commits yet on `master`. Keep it simple — meaningful messages, squash
before PR if needed.

## Tips for AI Agents

- There is no framework. CSS is hand-written with custom properties for theming
  and a single `@media (min-width: 540px)` breakpoint for desktop.
- The RNG logic uses `crypto.getRandomValues()` directly — do not replace it
  with `Math.random()`.
- `localStorage` persistence is JSON under a single key (`random-web-prefs`).
  Changing the shape of stored data may break existing sessions — handle
  gracefully.
- Animations are driven by CSS `@keyframes` and triggered by JS class toggles
  with `void el.offsetWidth` reflow hacks. Respect `prefers-reduced-motion`.
- Input validation caps range at 1,000,000 max difference. Min/max inputs
  themselves are unbounded (0–1,000,000).
