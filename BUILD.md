# Building Compositor

## The short version

The app is built **through GitHub Actions**, not on a local machine, unless that machine is a Mac with Xcode 26+.
Everything below assumes the repo is your fork (`origin`) with the default branch `main`.

- **Verify** (`.github/workflows/verify.yml`) runs on every push: a Debug build for `arm64` and `x86_64`, then the
  unit tests (macos-26 runner, Xcode pinned per workflow).
- **Build** (`.github/workflows/build.yml`) produces the shippable app: a Release `x86_64` (Intel, macOS 14.7+)
  `Compositor.app`, uploaded as a zip artifact. It runs on demand (`workflow_dispatch`) and on `v*` tags.

There is no local build on Linux or on a Mac without a full Xcode 26 — the project needs the Xcode 26 toolchain
(Swift 6.2 language features: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY`,
`nonisolated` on whole types). Parse-only syntax checks with any local Swift work fine:

```sh
swiftc -parse Compositor/**/*.swift
```

## Producing an Intel release build

```sh
gh workflow run build.yml --repo <owner>/Compositor --ref main
gh run watch --repo <owner>/Compositor $(gh run list --repo <owner>/Compositor --workflow=Build --limit 1 --json databaseId --jq '.[0].databaseId')
gh run download <run-id> --repo <owner>/Compositor -n Compositor-intel -D ~/Downloads/Compositor-intel
```

Or in the browser: Actions → **Build** → the finished run → Artifacts → `Compositor-intel`.
Unzip, move `Compositor.app` to `/Applications`, and open it the first time via **right-click → Open** (the build is
ad-hoc signed, so Gatekeeper has no Developer ID to verify).

## The toolchain cascade (why not just `-O` on the newest Xcode)

Xcode 26.4–26.6 (Swift 6.3.x) have a SIL-optimizer crash when **cross-compiling Release with optimization for
`x86_64`** (`-O` and `-Osize`; WMO or incremental, coverage on or off — all crash). Their Debug builds and every
`arm64` build are fine. Xcode 26.2 (Swift 6.2.x) compiles the same code optimized without issue.

So the Build workflow tries, in order, and keeps the first success (the winner is written to the step summary):

| Attempt | Toolchain | Optimization |
|---|---|---|
| 1 | Xcode 26.2 | `-O` (normally the one that wins) |
| 2 | Xcode 26.5 | `-O` |
| 3 | Xcode 26.4.1 | `-O` |
| 4 | Xcode 26.6 | `-Onone` (guaranteed fallback) |

All four are preinstalled on the `macos-26` runner image. If a future Xcode fixes the bug, reorder the list in
`build.yml` and drop the fallbacks.

## Building locally (Mac with Xcode 26+)

```sh
xcodebuild -project Compositor.xcodeproj -scheme Compositor -destination 'platform=macOS' build
xcodebuild -project Compositor.xcodeproj -scheme Compositor -destination 'platform=macOS' test -only-testing:CompositorTests
```

The deployment target is macOS 14.7 and `ARCHS` is `$(ARCHS_STANDARD)` (universal). For a Release `x86_64` build,
build on Xcode 26.2 or add `SWIFT_OPTIMIZATION_LEVEL=-Onone` for newer toolchains, per the cascade above.

## Platform notes

- Intel Macs (macOS 14.7+) are the target of the CI release build; the app also runs on Apple Silicon.
- Object Selection, Remove Background and Select Subject (Vision's instance-mask) only work on Apple Silicon; on
  Intel they fail with a clear message instead of crashing.
