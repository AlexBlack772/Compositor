# Compatibility with the original Compositor

This fork is the port of [Compositor](https://github.com/robbietilton/Compositor) to **Intel Macs on macOS 14.7+**
(upstream requires macOS 26, which no Intel Mac can run). The app also runs on Apple Silicon. Everything is
upstream's code; the port only lowers the deployment target and gates the few macOS 15+/26-only APIs behind
`#available` checks. So nearly all features behave exactly as in the original — this file lists what doesn't.

Current port: **Compositor 1.4.9**.

## Not available on this port

- **Object Selection, Remove Background and Select Subject** (Vision's foreground instance-mask requests) need
  Apple Silicon. On Intel they fail with a clear message instead of crashing. Selecting by hand — the rectangular
  and lasso tools, the Magic Wand, Select Color — is unaffected.
- **In-app updates.** The updater checks upstream's feed, whose releases require macOS 26, so Sparkle offers them
  to no one on this port ("no updates available"). To take a new upstream release, update this repository and
  rebuild through Actions — see [BUILD.md](BUILD.md).

## Works differently (macOS 14.7 vs 15/26 fallbacks)

These are all cosmetic; editing itself is identical.

- **Export As preview** — on macOS 15 the preview can be dragged around with a grab pointer and re-centers as you
  zoom. On macOS 14.7 it moves with the scroll wheel or trackpad only.
- **Frame-resize cursors** — crop and transform handles show the two-way frame-resize cursor on macOS 15; on
  macOS 14.7 the classic resize arrows (and custom-drawn diagonal arrows on the corners).
- **Panel dividers** — the column-resize pointer over a divider between panels exists from macOS 15; on macOS 14.7
  it stays the plain arrow. Dividing works the same.
- **Toolbar tab strip** — on macOS 26 the document tabs sit on a shared background between spacers; on earlier
  systems they are a plain toolbar item with a fixed gap beside it. Same tabs, slightly different spacing.
- **Capsule controls** — the blend-mode picker's and some type controls' segmented controls get capsule-shaped
  borders on macOS 26; on earlier systems the standard rounded bezels.

## Release-channel differences

- Builds come from this repository's GitHub Actions as the `Compositor-intel` artifact — a zip of an **ad-hoc
  signed** app. Gatekeeper has no Developer ID to verify, so open it the first time via **right-click → Open**.
  Upstream's notarized DMGs from its releases page will not run here.
- The CI release build is normally optimized (Xcode 26.2, `-O`). If a toolchain bug forces the unoptimized
  fallback, pixel operations run noticeably slower — the winning toolchain is recorded in the Build run's step
  summary. See the toolchain cascade in [BUILD.md](BUILD.md).
