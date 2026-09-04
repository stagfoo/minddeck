# Rolidecks

A portrait card-stack home launcher for the **iKKO Mind One** — a card-sized
Android 15 phone with a 1080 × 1240 panel. A rolodex you flip through, not a
grid you hunt in.

Each card is a coloured folder holding a sideways-scrolling row of apps. The
cards **overlap like a rolodex**: the first card is the front of the deck and
every card after it sits *behind* the one before, receding downward — so **all
apps**, always last, is always at the very back, and can't be moved or deleted.

A covered card reveals its **bottom strip** below the card in front of it, which
is why the name, count and mark live at a card's bottom edge: that strip is the
only part of it you can see. The focused card is revealed whole, and the cards
in front of it slide up until their bottoms meet its top edge — no card is ever
lifted out of the paint order, the positions alone do it.

Apps live **on** the card, in a row you scroll sideways. Sideways rather than a
wrapped grid because a card is wide and short, and because it keeps the vertical
gesture free for the stack — the one that has to stay reliable.

The phone has no scroll wheel, so the deck gets a **pull knob** down the right
edge instead — a ridged grip on a recessed track, wearing the focused card's
colour so the rail says which card you are on even while your thumb covers the
deck, with a haptic tick as each card takes focus. The **whole right band** is the grab area, top to bottom: a
thin track would be a hairline target on a screen this small, and the thumb
rests there anyway. Swiping the stack and tapping the track work too.

## Cards

Nothing sits above the deck: the front card starts at the top edge of the
screen, and **+** and settings live along the bottom-left instead. A bar over
the stack reads as a gap the cards start below, which undoes the impression
that they are a deck resting on the screen.

- **Tap** a collapsed card to focus it; tap the focused card to open it.
- **Hold** a card (or tap **+**) to open **Edit deck** — the whole deck in one
  scrolling list, every card showing what's on it.
- Deleting a card doesn't remove its apps — they stop being filed and reappear
  under all apps.

### Edit deck

Each row is a card with three things on it: a **move handle**, the **apps
already filed there**, and a **+** to add more.

- **Drag the handle** to move a card. Dragging is confined to the handle on
  purpose — that is what lets the list scroll. A drag anywhere on the row would
  fight the list's own scrolling, which is the conflict that makes these UIs
  feel broken.
- **Tap the card** — anywhere on it — to edit its colour, icon and name, or
  delete it. A small pencil marks it. The app chips, the + and the handle are
  children, so they are hit first and keep doing their own jobs.
- **Tap +** for a searchable, multi-select picker — a full screen, not a bottom
  sheet, so it never has to fight the keyboard for room. File a card's worth of
  apps in one go rather than one at a time. An app already on the card is greyed
  out, and one filed elsewhere says which card it will move from.
- **Tap an app** on a card to unfile it.

All apps sits at the bottom with no handle and no +: it is the back of the deck
and holds everything by definition.
- **+** in the top strip adds a card and opens the editor on it.
- Inside **all apps**, hold an app to file it under a card. An app lives on at
  most one card — two homes would show it twice and make removing it ambiguous.
- A dot on an app's icon in the all-apps grid means it's already filed, so
  what's left unfiled is obvious at a glance.

The palette is twelve saturated colours, all chosen to carry black text — that
constraint is what keeps the stack reading as one object rather than a bag of
swatches. The editor previews the real card and updates live as you pick, since
swatches alone don't tell you how a colour reads behind a label.

Colours and icons are stored as **keys**, not raw values, so retuning the
palette restyles existing decks, and a deck written by a future build with
colours this one doesn't know still opens rather than crashing.

## Fitting the panel

`solveStack` fits the deck into whatever height it's given: it squeezes the
strips first, then the card, because a slightly shorter card costs less than
strips too thin to read a name in. Both have floors — the strip's floor is the
card header, since the strip is *all you see* of a covered card. When even
those don't fit, the stack reports that it overflows and scrolls, rather than
crushing the strips until the labels clip.

| Density | Box | 7 cards | 9 cards |
| --- | --- | --- | --- |
| 2.5× | 440dp | 158dp card, 44dp strips | 158 / 35 |
| 2.75× | 395dp | 158dp card, 39dp strips | 139 / 32 |
| 3.0× | 357dp | 158dp card, 33dp strips | scrolls |

Which density is real depends on what the phone reports. **Long-press the
clock** and it tells you — measured, not assumed. `StackStyle` in
`lib/stack_layout.dart` holds the four numbers that decide the proportions.

The knob shrinks as the deck grows, like a scrollbar thumb, so its size reads
as "how much deck there is" with no extra chrome. `solveKnob` and
`cardIndexForKnobPosition` are tested as exact inverses — if they disagree the
grip drifts out from under your finger mid-drag, which feels broken even when
the selection is right.

## Using it as the home app

1. Install the APK.
2. Open Rolidecks once from your current launcher — it keeps a `LAUNCHER` intent
   filter for exactly this.
3. Tap the banner it shows to land in **Settings → Apps → Default apps → Home
   app**, and pick Rolidecks.

There is no API to set the default home app directly, by design, so that picker
is the whole of "make me the launcher".

**If the Home-app slot isn't offered at all**, iKKO's AI OS has pinned it and no
third-party launcher will work on this device.

Orientation is `portrait` in `AndroidManifest.xml`. The layout solves for
whatever box it gets, so changing that one attribute is all a different
orientation needs.

## Layout

Everything worth being sure about is plain Dart with no Flutter or plugin
imports, so it's testable with no device attached:

| File | Does |
| --- | --- |
| `lib/card_deck.dart` | Cards, folders, filing, reorder, persistence |
| `lib/card_style.dart` | The closed palette and icon-key catalogue |
| `lib/stack_layout.dart` | Stack geometry and knob position |
| `lib/models.dart` | `LaunchableApp`, `ScreenMetrics` |
| `lib/launcher_bridge.dart` | The only platform-channel code on the Dart side |
| `lib/home_screen.dart`, `lib/deck_card_view.dart`, `lib/side_rail.dart`, `lib/card_editor_sheet.dart`, `lib/folder_screen.dart`, `lib/app_tile.dart`, `lib/theme.dart`, `lib/status_strip.dart` | The UI |
| `android/…/MainActivity.kt` | The only Android code |

The Kotlin side lists **launchable activities** (`queryIntentActivities` on
`MAIN`/`LAUNCHER`) rather than installed packages — that's the list a launcher
is supposed to show, it excludes services and libraries for free, and it
correctly surfaces packages exposing more than one launcher entry. It also
watches package add/remove broadcasts so the deck redraws rather than holding a
card for an app that's gone.

## What it deliberately doesn't do

- **App widgets.** `AppWidgetHost` from Flutter is genuinely painful, and there
  is nowhere to put them on this screen.
- **Notification badges** and **icon packs.**

If any of those turn out to matter, forking [Fossify Launcher](https://github.com/FossifyOrg/Launcher)
(Kotlin, small, readable) is the sane alternative base.

## Type

Labels are set in [Lexend](https://github.com/googlefonts/lexend) — bundled in
`assets/fonts/`, not fetched with `google_fonts`: a launcher has to draw its own
labels without a network, and a first-run flash of a fallback font on the home
screen would be the first thing you ever see of it. SIL Open Font Licence 1.1,
included as `assets/fonts/OFL.txt`.

It ships as one variable font with a `wght` axis, so `deckText()` in
`lib/theme.dart` sets both `fontVariations` and `fontWeight`. Measured on this
engine `fontWeight` alone already drives the axis, so that is belt-and-braces
rather than a workaround — and `test/font_test.dart` measures real glyph widths
at three weights, loading the font file itself, because `flutter test` otherwise
renders with a placeholder whose glyphs are all the same width and every weight
would measure identically.

## Installing with Obtainium

[Obtainium](https://github.com/ImranR98/Obtainium) tracks the GitHub releases
and installs updates, which beats downloading an APK by hand every time.

**Add it:** [obtainium://app/…](obtainium://app/%7B%22id%22%3A%22com.rolidecks.rolidecks%22%2C%22url%22%3A%22https%3A%2F%2Fgithub.com%2Fstagfoo%2Frolidecks%22%2C%22author%22%3A%22stagfoo%22%2C%22name%22%3A%22Rolidecks%22%7D) — or paste
`https://github.com/stagfoo/rolidecks` into Obtainium's Add App screen. The
config the link carries is just id, url, author and name; no extra settings are
needed, because releases are shaped to Obtainium's defaults:

- **The tag is exactly the version** — `1.0.1`, not `v1.0.1-3d1885e`. Obtainium
  compares the version a release advertises against the version Android reports
  for the installed app, and can only do that when the two are the same shape.
  A tag carrying a `v` and a commit sha would need a `versionExtractionRegEx`
  set by hand.
- **Every release bumps the version and the build number.** Shipping the same
  version twice leaves Obtainium nothing to compare and Android no reason to
  treat the APK as an update.
- **One APK asset per release**, so no `apkFilterRegEx` is needed.

The repo is public so that this needs no token. While it was private, GitHub's
API answered anonymous requests with a 404 rather than a 403 — it hides private
repos rather than admitting they exist — and Obtainium surfaced that as
"Could not find a suitable release", which reads like a problem with the
releases rather than with access to them.

`android/app/debug.keystore` is public along with everything else. It is a
debug-only key with the standard `android` password and is not used for release
signing, but it does mean the signature on these APKs is not a secret: anyone
could sign an APK that Android would accept as an update to Rolidecks. They would
still have to get it onto the phone, and nothing here is distributed through a
store, so the exposure is small — but it is the reason to think twice before
reusing this pattern for anything that matters.

Releases before `1.0.1` used the old `v1.0.0-<sha>` tag format and will not
compare cleanly; the first Obtainium-tracked version is `1.0.1`.

This app was called MindDeck until `1.0.5`. The rename changed the Android
applicationId, so Android treats Rolidecks as a new app rather than an update:
remove the old Obtainium entry and add this one, set Rolidecks as the home app,
and uninstall MindDeck once you are happy. The deck does not carry over — an
applicationId is an app's identity, and a different one gets its own storage.

## The launcher icon

Material Icons' `style` — a fanned stack of cards, which is what this is — as an
adaptive icon: black glyph on the app's accent, the same black-on-saturated
arrangement the cards use. `minSdk` is 26, so every device that can run this
supports adaptive icons and there are no bitmap mipmaps to keep in step; the
same vector doubles as the `monochrome` layer for Android 13+ themed icons.

The glyph's own bounding box is neither centred in its 24-unit viewbox nor
square (x=1.295, y=2.75, 20.885 × 19), so centring it by eye leaves it low and
left. The scale and offset in `ic_launcher_foreground.xml` are derived from that
measured box, and place it dead centre at 60.6 × 55.1 units — inside the 72-unit
safe zone whatever shape a launcher's mask crops to.

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

Releases are **release** builds, not debug ones — ~18MB against ~80MB, and more
importantly AOT-compiled instead of running Dart in the JIT. For a home app cold
start *is* the experience: every swipe up that had to restart the process pays
it, and a debug build makes that several times slower, which reads as the
launcher not being there. They are arm64-only and signed with the same committed
`debug.keystore`, so they install as updates over anything built before.

`android/app/proguard-rules.pro` exists because the release build could not run
without it. `flutter analyze` and `flutter test` never touch Gradle, so a broken
release config sits invisible until someone actually builds one — which is worth
doing after any change to the Android side, not just before shipping.

Two other things a launcher pays for on every cold start, both fixed here:
the window Android paints before Flutter's first frame is the deck's own
background rather than the template's white, and the home screen renders from
local storage immediately, asking the platform afterwards instead of holding a
spinner until it answers.

## The app snapshot

Asking the platform for every launchable activity is the slowest thing the
launcher does, and it sits on the path to the first useful frame: until it
returns there are no apps on the cards and nothing to search. `lib/app_cache.dart`
keeps a JSON snapshot of the list, so a cold start draws the real deck straight
away and the platform's answer only redraws anything if it actually differs.

The snapshot is a cache, never the truth. It is refreshed:

- **when a package changes** — the Kotlin side broadcasts install, removal,
  replacement and change events over an EventChannel;
- **on resume**, which catches whatever those miss — a shortcut added, an app
  relabelled, a locale change;
- **on demand**, with the refresh button in the bottom-left row.

A refresh that finds nothing new does not call `setState`. Since the launcher
refreshes on every resume, rebuilding the deck each time you came home would
undo the point of caching it — so `appListsDiffer` compares ids and labels
first. An unreadable or future-schema snapshot is treated as a miss rather than
an error, because refetching from the platform is always safe.
