# v3 MOTION PASS — Final Report

Branch `feat/ui-design-system`, commits `1da5279` → `e14007c` (6 commits, one per
step plus tests). Goal: make the v2 "Soft Neo-Organic Minimalism" skin alive —
animated gradient mesh, animated geometric patches, animated hub orbit rings —
plus the dock contrast fix, without touching business logic.

## 1. Commits and files changed

| Step | Commit | Message | Files |
|------|--------|---------|-------|
| 1 | `1da5279` | shared ambient clock, motion tokens, ambient motion provider | `lib/core/motion/motion_tokens.dart` (new, 121), `lib/core/motion/ambient_clock.dart` (new, 265), `lib/app.dart` (`AmbientClock` above `MaterialApp.router`), `test/widget_test.dart` (motion-off override) |
| 2 | `f70ba56` | animated mesh gradient — Lissajous drift, neighbor cross-fade, 4th wash, 30fps throttle | `lib/core/widgets/app_backdrop.dart`, `lib/core/theme/app_colors.dart` + `app_tokens.dart` (`meshButter` in all 7 spots), `tool/check_contrast.dart` (+15 pairs) |
| 3 | `ed185ab` | animated geometric patches | `lib/core/widgets/app_backdrop.dart` |
| 4 | `13d7170` | animated hub orbit rings — marching dashes, comet, satellites, ripple | `lib/features/home/widgets/hub_rings_painter.dart` (new, 221), `node_painter.dart` (orbit removed, −42), `node_home_screen.dart` (rings layer) |
| 5 | `ae3592e` | dock opaque ink fill for contrast, root crumb as overline | `lib/core/widgets/floating_dock.dart`, `node_home_screen.dart`, `glass_panel.dart` (doc), format-only touch-ups elsewhere |
| 6 | `e14007c` | ambient clock demand tests | `test/ambient_clock_test.dart` (new) |

## 2. Motion tokens (single tuning point: `lib/core/motion/motion_tokens.dart`)

All values are deterministic `base + A·sin(2πt/T + phase)` or linear sweeps over
shared clock seconds `t`; prime-ish period family (14/17/21/26/29/30/31/34/37/40)
so nothing visibly loops in sync.

| Element | Token | Value |
|---|---|---|
| Mesh tick | `meshTickDivisor` | 2 → 30fps (from 60fps clock) |
| Mesh blob drift | `meshDrift` | 4 Lissajous paths, amplitudes 11–16% of canvas, periods 20–40s, phases 0/1.3/2.6/4.1 |
| Mesh cross-fade | `meshCrossPeriodA/B/C` | 34s, 40s, 29s (lavender↔peach↔sage), phases 0.5/2.1/3.7 |
| Mesh alpha | `meshAlphaLight/Dark` | 0.50 / 0.30 (butter × `meshButterAlphaScale` 0.6) |
| Patch drift / rotate / breathe | `patchDriftMaxDp` / `patchRotationMaxRad` / `patchBreatheAmp` | 16dp / 0.1047rad (~6°) / ±4% |
| Patch periods | `patchPeriods` | [14, 17, 21, 26, 30]s per preset index, phases [0, 1.1, 2.4, 3.9, 5.2] |
| Patch morph | `patchMorphPeriod` | 26s, circle ↔ squircle corner-radius lerp (one patch per preset, hub/list/form) |
| Dash march | `ringDashPeriod` | 40s per revolution, clockwise |
| Comet | `ringCometPeriod` / `ringCometSweepRad` | 18s (fastest motion in app), 70°, counter-clockwise, glow α 0.16 |
| Satellites | `ringSatellitePeriods` | 21 / 26 / 31s counter-clockwise, 4.5dp, phases 0/2.1/4.2 |
| Ripple | `ripplePeriod` / `rippleGrowSeconds` / `rippleAlpha` | every 6s, 2.4s easeOut grow, α 0.12 → 0 |

## 3. How it's wired

* **One shared Ticker** (`ambient_clock.dart`): a raw `Ticker` owned by
  `_MotionCore`, driven by a monotonic elapsed-seconds accumulator (delta
  accumulation — no `AnimationController` 1h repeat, so no phase jump). It
  exposes two dirty-notifiers: `fast` (60fps, patches/rings) and `slow` (60/2 =
  30fps, mesh). Painters subscribe via `CustomPainter(repaint:)` →
  `RenderCustomPaint.addListener` (delegates to the repaint listenable,
  verified in `rendering/custom_paint.dart:163`).
* **Demand-driven**: the ticker starts only while ≥1 painter is subscribed
  (`_GatedNotifier` listener-count gate) AND the app is resumed AND motion mode
  allows it. Nothing subscribes → ticker disposed/stopped. `ref.listen` on
  `ambientMotionProvider` re-evaluates on mode change; mode `off` zeroes `_seconds`
  and never starts.
* **Route/lifecycle gating**: `AmbientClock.motionOf(context)` returns
  `MotionRead.still` (seconds ≡ 0, silent notifier) when
  `MediaQuery.disableAnimationsOf` is true (reduce-motion),
  `TickerMode.valuesOf(context).enabled` is false (deprecated `TickerMode.of`
  avoided), no ambient clock ancestor, or the current route
  `ModalRoute.isCurrent` is false (covered routes freeze; navigator's own
  TickerMode also handles offstage routes). `AmbientObserver` pauses the ticker
  on non-resumed app lifecycle.
* **Gesture/safety contract**: every animated painter sits behind
  `IgnorePointer` (or inside the existing GestureDetector with the nodes), has
  no semantics contribution, and overrides `hitTest => false`
  (`RenderCustomPaint.hitTestSelf` would otherwise default to true). Decorations
  never intercept taps; node taps still work (GestureDetector wraps the canvas).
* **Repaint isolation**: mesh and patches each sit in their own
  `RepaintBoundary`; rings in an explicit one behind the node canvas.
  Screen max respected: 1 full-screen animated painter + patch layer + hub rings.

## 4. Degrade ladder (frame budget)

Encoded in `meshTickDivisor` doc; apply in order if frame times regress:
1. `meshTickDivisor` 2 → 3 (mesh 30fps → 20fps).
2. Disable satellites + ripple (`ringSatellitePeriods` / `ripplePeriod` use).
3. Static mesh (painter ignores `slow` — pass a `still` read).
4. Static patches (same).
The comet head glow (`ringCometGlowAlpha`) is the first visual droppable.

## 5. Dock contrast fix (step 5)

* `FloatingDock`: glass → opaque `tokens.dockSurface` fill (+1dp `outline` in
  dark only, `shadowEDock`, restored 16/12/12/12 padding). `onInk` title,
  `onInk`@72% subtitle — all restore ≥4.5:1. Post pill stays solid
  `brandPrimary` with `brandOnPrimary` label (white fails on `#9B7BFF`, so dark
  uses `#12082E` — approved assumption #3).
* Hub root crumb → bare uppercase overline (labelSmall, w600, letterSpacing 1.2,
  `inkMuted`), `onCrumbTap` kept. Non-root crumbs keep the highlighted-pill
  logic (`highlighted = isLast`).
* `GlassPanel` is now unused by the dock (doc updated) — still available for
  header clusters/sheets.

## 6. Verification (all run locally, no CI)

| Gate | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **25/25 passed** (22 prior + 3 clock tests) |
| `dart tool/check_hardcoded_colors.dart` | OK — no hardcoded colors outside `lib/core/theme/` |
| `dart tool/check_contrast.dart` | **All 83 pairs meet target** (was 68 in v2; +15 for butter/dark mesh/light inkMuted-over-mesh/dock pairs) |

Clock tests (`test/ambient_clock_test.dart`): auto mode advances seconds and
stops on unmount; `ambientMotionProvider = off` stays frozen at t=0; reduce-motion
(MediaQuery `disableAnimations`) returns `still`. Note: `pumpAndSettle` must not
be used while the ticker runs (it schedules frames by design) — tests use
explicit `pump(Duration)`; all other suites pump raw screens without a clock
ancestor, so they were unaffected.

## 7. Skipped / deferred (per escape clauses)

* **Parallax on pointer/touch** — skipped (motion spec allows; cost/benefit).
* **Detail-screen morph** — the detail preset has no circle patch, so it keeps
  geometric patches (drift/rotate/breathe only).
* **Glow droppable** — comet head glow marked droppable in tokens.

## 8. Device captures (to be recorded on an emulator/device)

This environment has no emulator; run on yours:

1. **Screenshots (light + dark)**: `flutter run` (Cloudinary dart-defines in
   `.vscode/launch.json` are not needed for capture), open the hub, capture at
   t≈0s, t≈6s, t≈12s → `flutter screenshot -o shot_t6.png` (repeat). Expect:
   visibly different mesh blob positions/colors, patch positions, ring
   dash/comet/satellite positions between frames.
2. **Frame times (profile mode)**:
   `flutter run --profile` on **Medium Phone** profile and on a **360×640**
   AVD; open DevTools → Performance, record ~10s on the hub while the mesh +
   rings animate; note **avg frame build time** and **avg raster time** (target
   ≤16ms total). Slots to report: hub idle, hub expanding a node, feed/list
   scroll (mesh + patches animating).
3. **Reduce-motion check**: OS "Remove animations" on → static t=0 frame,
   no animated repaints (DevTools should show no frame traffic beyond input).
4. **Motion-off check**: `ambientMotionProvider` overridden to `AmbientMotion.off`
   → frozen frame identical across screenshots.
