# MindDeck

A portrait card-stack home launcher for the **iKKO Mind One** — a card-sized
Android 15 phone with a 1080 × 1240 panel.

Each card is a coloured folder holding a sideways-scrolling row of apps. The
cards **overlap** like a wallet: every card is drawn full height and offset by
less than that, so each one slides under the next and you see its top strip —
name, count, mark — with its lower half and bottom corners hidden behind the
card in front. The focused card is the exception: everything after it is pushed
clear of its bottom edge, so it's revealed whole. The last card is **all apps**
and can't be moved or deleted.

Apps live **on** the card, in a row you scroll sideways. Sideways rather than a
wrapped grid because a card is wide and short, and because it keeps the vertical
gesture free for the stack — the one that has to stay reliable.

The phone has no scroll wheel, so the deck gets a **pull knob** down the right
edge instead — a ridged grip on a recessed track that you drag up and down,
with a haptic tick as each card takes focus. Swiping the stack and tapping the
track work too; the knob is the deliberate affordance, not the only one.

## Cards

- **Tap** a collapsed card to focus it; tap the focused card to open it.
- **Hold** a card to edit its **name, colour and icon**.
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
2. Open MindDeck once from your current launcher — it keeps a `LAUNCHER` intent
   filter for exactly this.
3. Tap the banner it shows to land in **Settings → Apps → Default apps → Home
   app**, and pick MindDeck.

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
