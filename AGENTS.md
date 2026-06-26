# AGENTS.md — random-web

## Project Status

Single-page PWA. Plain HTML/CSS/JS with Alpine.js loaded from CDN — no build
step, no npm, no local dependencies.

## Architecture

`index.html` is the entire application: CSS in a `<style>` block, markup in
`<body>`, and JS in a `<script>` block at the bottom. Alpine.js (v3.14.9,
pinned CDN URL) drives reactivity via **three components** registered inside
an `alpine:init` listener:

| Component | `x-data` on | Owns |
|---|---|---|
| `app` | `.app` (root div) | `activeTab`, `switchTab()`, `persistTab()` |
| `numbersPanel` | Numbers `.tab-panel` | Min/max state, generation, shuffle, diagnostic, copy |
| `coinPanel` | Coin `.tab-panel` | Coin state, toss animation, stats, persistence |

`numbersPanel` and `coinPanel` access `activeTab` from `app` via Alpine's
scope chain (parent properties are readable in child template expressions).
Neither child reads `activeTab` in JS methods — the scope dependency is
template-only.

The app has two tabs sharing one `.card` layout:

- **Numbers** — min/max bounds, CSPRNG integer generation, Fisher-Yates range
  shuffle, in-browser CSPRNG diagnostic, clipboard copy
- **Coin Toss** — CSPRNG boolean toss, animated flip, H/T stats tracker with
  session persistence

Data flow:
1. Each component's `init()` calls `getPrefs()` → populates its own state
2. `$watch` on `min`, `max` (in `numbersPanel`) and `activeTab` (in `app`)
   auto-persist to `localStorage` via `updatePrefs(patch)`
3. `crypto.getRandomValues()` feeds `secureRandomInt()` (rejection-sampled
   Uint32) and `secureRandomBoolean()` (bit-0 of Uint8)
4. Results display with CSS animations triggered by Alpine state flags

## Key Files

| File | Purpose |
|---|---|
| `index.html` | Entire app: structure, styles, logic |
| `sw.js` | Service worker — cache-first PWA offline support |
| `manifest.json` | PWA manifest (standalone display, SVG + 192/512 PNG icons) |
| `icon.svg` | Vector app icon (used directly + rendered to PNGs) |
| `icon-192.png` | App icon at 192×192 (PWA / manifest) |
| `icon-512.png` | App icon at 512×512 (splash / apple-touch) |
| `_test_random.py` | Python CSPRNG statistical verification |
| `coin-heads.png` | Heads face image (200×197, grayscale PNG) |
| `coin-tails.png` | Tails face image (200×200, RGBA PNG) |

## Build / Test / Run

No build system. To run: open `index.html` in any modern browser, or serve
with any static file server.

**Statistical test** (validates CSPRNG algorithms against OS randomness):
```
python3 _test_random.py
```
Runs 100k iterations for integer distribution and 1M for coin bit fairness.

## localStorage Schema

All persistence lives under a **single key** `"random-web-prefs"` as JSON:

```json
{
  "min": 1,
  "max": 100,
  "tab": "numbers",
  "coinStats": { "heads": 42, "tails": 38 }
}
```

Each write goes through `updatePrefs(patch)` which merges the patch into the
stored object. Reads go through `getPrefs()` which always returns a
fully-typed, defaults-applied object — callers never need to guard types.
Adding a new persistent key means updating `PREF_DEFAULTS` and `getPrefs()`'s
return shape in one place.

## PWA / Service Worker

`sw.js` uses cache-first strategy under key `"random-web-v3"`. If assets are
changed and need cache-busting, **increment the cache string** in `sw.js`.
The service worker is registered unconditionally at script load via
`navigator.serviceWorker.register("sw.js")`.

## Alpine.js Patterns

- Four components: `app` (root), `numbersPanel` (numbers div), `diagnostic`
  (diag-section div inside numbers), `coinPanel` (coin div) — all registered
  via `Alpine.data()` in one `alpine:init` handler
- Tab visibility: **both** `x-show="activeTab === '...'"` (Alpine) **and**
  `:class="{ active: activeTab === '...' }"` (CSS) are applied to panels.
  Do not remove either — `x-show` controls DOM visibility; the CSS class is
  used for potential styling hooks.
- `activeTab` lives on `app`. Child panels read it in templates via Alpine
  scope chain. In JS methods, `this.activeTab` is **not** accessible inside
  `numbersPanel`/`coinPanel` — Alpine's `$parent` is not a valid magic
  property on `this` in JS methods; use `$dispatch` events instead.
- `diagnostic` is a **direct child** of `numbersPanel` in the DOM. Its
  `runDiagnostic()` reads `this.validateBounds()`, `this.min`, `this.max`,
  and writes `this.error` — all resolved through Alpine's merged scope chain
  to `numbersPanel`. Moving the `.diag-section` element outside the
  `numbersPanel` subtree will silently break these reads.
- DOM refs: `x-ref="coinDisplay"` on the coin element is scoped to `coinPanel`;
  accessed via `this.$refs.coinDisplay` inside coinPanel methods only.
- Async tick: `this.$nextTick(() => { ... })` is used to reset and re-set
  animation flags (e.g., `showPop`) so the CSS `@keyframes` re-fires.

## Animation Patterns

Two distinct patterns coexist:

1. **Number pop / shuffle pop** — Alpine flag toggle via `$nextTick`:
   ```js
   this.showPop = false;
   this.$nextTick(() => { this.showPop = true; });
   ```
2. **Coin flip** — direct DOM manipulation with `void el.offsetWidth` reflow
   hack to restart the CSS animation on each flip cycle:
   ```js
   el.classList.remove("flip");
   void el.offsetWidth;   // forces reflow — do not remove
   el.classList.add("flip");
   ```

`prefers-reduced-motion` is respected in **both** CSS (`@media` block disables
animations) and JS (the `tossCoin` function checks `matchMedia` at runtime and
skips the flip loop entirely).

## Coin Face Images

`coin-heads.png` and `coin-tails.png` are standalone files served alongside
`index.html`. The `.coin` div shows them via an `<img class="coin-face"
x-ref="coinFace">` child; `showCoinFace(isHeads)` sets `img.src` and toggles
`hidden`. A `<span x-ref="coinPlaceholder">?</span>` sibling shows the
pre-toss state; `resetCoinStats()` restores it by hiding the img and
un-hiding the span. Both PNGs are preloaded in `<head>` and listed in the
`sw.js` ASSETS array.

## RNG Implementation Notes

- `secureRandomInt(min, max)` — rejection sampling over Uint32 to eliminate
  modulo bias. The loop rejects values ≥ `maxValid` where
  `maxValid = 0xffffffff - (0xffffffff % range)`.
- `secureRandomBoolean()` — reads bit-0 of a single Uint8 (`(buf[0] & 1) === 0`
  → heads).
- `Math.random()` **is intentionally used** in one place: computing the number
  of visual coin flip cycles (`3 + Math.floor(Math.random() * 3)`). This is
  purely cosmetic decoration, not the actual toss result.
- Never substitute `Math.random()` for either CSPRNG function.

## Shuffle Range

`shuffleRange()` builds an array of every integer in `[min, max]` and runs
Fisher-Yates using `secureRandomInt`. Display is capped: ≤ 1000 items shown
in full; > 1000 shows first/last 20 with `...` in between.

## Input Validation

- Range difference capped at 1,000,000 (`max - min > 1_000_000` → error).
- Min/max inputs: `min="0" max="1000000"` on HTML elements, but validation is
  also enforced in `validateBounds()` in JS.
- Enter key on either input triggers `persistBounds(); generateNumber()`.

## Styling Conventions

- All design tokens are CSS custom properties in `:root` (colors, radii, fonts).
- Dark-only theme — no light mode. Accent color: `--accent: #7c5cfc`.
- Single responsive breakpoint: `@media (min-width: 540px)`.
- Font stacks reference system fonts; no web font loading.
- Monospace stack (`--font-mono`) used for result values and diagnostic output.

## Tips for AI Agents

- **Alpine CDN version is pinned** at `3.14.9` in the `<script>` tag. Do not
  bump it without testing — Alpine minor versions can have breaking API changes.
- **No PostCSS / autoprefixer.** Write CSS that already works in modern
  browsers.
- **`sw.js` cache key** must be bumped when modifying any cached asset path
  listed in `ASSETS` array, or browsers will serve stale content.
- The in-browser diagnostic (`runDiagnostic`) uses `setTimeout(..., 50)` to
  yield to the UI thread before running 100k iterations synchronously.
