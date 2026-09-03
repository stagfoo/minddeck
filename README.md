# MindDeck

A landscape, Switch-style home launcher for the **iKKO Mind One** — a card-sized
Android 15 phone whose panel is 1080 × 1240, i.e. **1240 × 1080 in landscape**.

## Why it isn't a copy of the Switch home screen

The Switch shows a *single horizontal row* of large rounded-square cards because
a TV is 16:9. This panel is about **1.15:1 — near square**. One row would leave
most of the height empty and shrink the tiles for no reason.

So MindDeck keeps the Switch's visual language — near-black ground, large
rounded-square cards, a bright cyan rim and lift on whatever is selected, a thin
clock strip up top, a system-button row along the bottom — and lays it out as a
**grid**. `solveGrid` picks the column count that gets tiles closest to a target
size, then fills the height with rows. On this panel that lands at:

| Density | Landscape dp | Grid | Tile |
| --- | --- | --- | --- |
| 2.5× | 496 × 432 | 4 × 2 | 106 dp |
| 2.75× | 451 × 393 | 3 × 2 | 130 dp |
| 3.0× | 413 × 360 | 3 × 2 | 118 dp |

Which of those is real depends on the density the phone reports. **Long-press
the clock** and it tells you — measured, not assumed. If the tiles come out
wrong, `GridStyle.targetTileSize` in `lib/grid_layout.dart` is the one number
that decides how console-like the grid feels.

## Using it as the home app

1. Install the APK.
2. Open MindDeck once from your current launcher — it keeps a `LAUNCHER` intent
   filter for exactly this.
3. It shows a banner saying it isn't the home app yet; tap it to land in
   **Settings → Apps → Default apps → Home app**, and pick MindDeck.

There is no API to set the default home app directly — by design — so that
picker is the whole of "make me the launcher".

**If the Home-app slot isn't offered at all**, iKKO's AI OS has pinned it and no
third-party launcher will work on this device. Worth checking before investing
in the design.

Orientation is set in `AndroidManifest.xml` as `sensorLandscape` — landscape,
either way up. Change that one attribute for portrait; the grid solves for
whatever box it gets, so the layout follows without further edits.

## Using it

- **Tap** a tile to launch.
- **Hold** a tile for remove-from-deck / app info / uninstall.
- **All apps** (bottom row) or the search icon opens everything installed;
  **hold** an app there to pin or unpin it from the deck.
- The deck reseeds itself on first run so the first boot isn't an empty screen,
  preferring user-installed apps over OEM plumbing.

Pinned ids of uninstalled apps are deliberately kept, so reinstalling an app
puts it back in its old slot instead of at the end.

## Layout

Everything worth being sure about is plain Dart with no Flutter or plugin
imports, so it's testable with no device attached:

| File | Does |
| --- | --- |
| `lib/grid_layout.dart` | Solves the tile grid for whatever box it's given |
| `lib/app_order.dart` | The deck: pin, unpin, reorder, seed, search |
| `lib/models.dart` | `LaunchableApp`, `ScreenMetrics` |
| `lib/launcher_bridge.dart` | The only platform-channel code on the Dart side |
| `lib/home_screen.dart`, `lib/all_apps_sheet.dart`, `lib/app_tile.dart`, `lib/theme.dart`, `lib/status_strip.dart` | The UI |
| `android/…/MainActivity.kt` | The only Android code |

The Kotlin side lists **launchable activities** (`queryIntentActivities` on
`MAIN`/`LAUNCHER`) rather than installed packages — that's the list a launcher
is supposed to show, it excludes services and libraries for free, and it
correctly surfaces packages exposing more than one launcher entry.

## What it deliberately doesn't do

- **App widgets.** `AppWidgetHost` from Flutter is genuinely painful, and on a
  4" square screen there's nowhere to put them.
- **Notification badges** and **icon packs.**

If any of those turn out to matter, forking [Fossify Launcher](https://github.com/FossifyOrg/Launcher)
(Kotlin, small, readable) is the sane alternative base.

## Building

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

`android/app/debug.keystore` is committed on purpose (debug-only, never used for
release signing) so local and CI builds share one signing identity and can
install over each other. That matters more than usual here: replacing the home
app means uninstalling it first, which drops you back on the stock launcher.

Release APKs are arm64-only — a debug build bundles a full Flutter debug engine
per ABI, so a universal APK is ~160MB against ~80MB for one.
