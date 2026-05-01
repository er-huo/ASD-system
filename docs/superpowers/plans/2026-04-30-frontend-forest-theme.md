# Frontend Forest Theme Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the Flutter frontend into a warm, ASD-friendly forest storybook interface across Splash, Home, Training, and Summary screens while preserving existing functionality.

**Architecture:** Keep interaction and layout in Flutter widgets, move atmospheric art into generated image assets, and introduce a small shared visual system so all four pages use the same palette, card language, and decorative background treatment. Preserve the existing animated Tino widget as the primary companion element during training.

**Tech Stack:** Flutter, Material 3, go_router, flutter_test, generated PNG illustration assets, existing Tino widget, fl_chart.

---

## File map

### Existing files to modify
- `flutter_app/lib/main.dart` — apply app-wide forest theme and typography defaults
- `flutter_app/pubspec.yaml` — register any new generated image asset directories
- `flutter_app/lib/screens/splash_screen.dart` — redesign onboarding / profile selection page
- `flutter_app/lib/screens/home_screen.dart` — redesign activity selection page
- `flutter_app/lib/screens/training_screen.dart` — redesign training layout and Tino prominence
- `flutter_app/lib/screens/summary_screen.dart` — redesign completion / report page
- `flutter_app/lib/widgets/activity_card.dart` — convert activity card from color block to illustrated story card

### New files to create
- `flutter_app/lib/config/forest_theme.dart` — shared palette, gradients, spacing, card shadows, text styles
- `flutter_app/lib/widgets/page_background.dart` — reusable decorative forest background layer
- `flutter_app/lib/widgets/decorated_card.dart` — reusable rounded cream card shell
- `flutter_app/lib/widgets/section_title.dart` — consistent title/subtitle block
- `flutter_app/lib/widgets/soft_status_badge.dart` — low-stimulation badge for camera / helper status
- `flutter_app/lib/widgets/activity_illustration.dart` — maps activity keys to local generated image assets

### Asset directories to create
- `flutter_app/assets/images/ui/` — generated splash hero, corner decorations, report decorations
- `flutter_app/assets/images/activities/` — generated activity illustrations

### Tests to create or update
- `flutter_app/test/widgets/forest_ui_smoke_test.dart` — verifies themed page shells render key content without crashing
- `flutter_app/test/widgets/activity_card_test.dart` — verifies illustrated card structure
- `flutter_app/test/widgets/tino_robot_test.dart` — update only if layout assumptions changed

---

## Chunk 1: Shared visual system and asset plumbing

### Task 1: Register new asset directories

**Files:**
- Modify: `flutter_app/pubspec.yaml`

- [ ] **Step 1: Write the failing smoke test reference for future assets**

Add a placeholder widget test in `flutter_app/test/widgets/forest_ui_smoke_test.dart` that pumps a future `PageBackground` using a known asset path from `assets/images/ui/`.

```dart
testWidgets('forest background renders with configured asset shell', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: SizedBox.expand()),
    ),
  );

  expect(find.byType(Scaffold), findsOneWidget);
});
```

- [ ] **Step 2: Run the test to verify baseline passes before asset wiring**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart`
Expected: PASS with placeholder test

- [ ] **Step 3: Add asset directories to `pubspec.yaml`**

Add:
- `assets/images/ui/`
- `assets/images/activities/`

Do not remove existing image/audio/video asset entries.

- [ ] **Step 4: Run Flutter pub get / lightweight validation**

Run: `flutter pub get`
Expected: completes without asset manifest errors

- [ ] **Step 5: Commit**

```bash
git add flutter_app/pubspec.yaml flutter_app/test/widgets/forest_ui_smoke_test.dart
git commit -m "feat: register forest ui asset directories"
```

### Task 2: Introduce a shared forest theme file

**Files:**
- Create: `flutter_app/lib/config/forest_theme.dart`
- Modify: `flutter_app/lib/main.dart`
- Test: `flutter_app/test/widgets/forest_ui_smoke_test.dart`

- [ ] **Step 1: Write a failing widget test for themed app shell**

Extend `forest_ui_smoke_test.dart` with a test that pumps the app or a `MaterialApp` using the future `forestTheme` and asserts warm background / MaterialApp loads.

```dart
testWidgets('forest theme material app builds', (tester) async {
  await tester.pumpWidget(MaterialApp(theme: forestTheme, home: const Placeholder()));
  expect(find.byType(Placeholder), findsOneWidget);
});
```

- [ ] **Step 2: Run the new test to verify it fails**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: FAIL because `forestTheme` is undefined

- [ ] **Step 3: Write minimal shared theme implementation**

In `forest_theme.dart`, define:
- core palette constants (`cream`, `sage`, `warmOrangeBrown`, `softGold`, etc.)
- app background gradient helpers
- `ThemeData forestTheme`
- a few reusable radii / shadow constants
- optional helper methods like `forestCardDecoration()` only if reused immediately

- [ ] **Step 4: Wire `main.dart` to use the new theme**

Replace the simple `ThemeData(colorSchemeSeed: ...)` with `forestTheme`.

- [ ] **Step 5: Re-run the test**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/config/forest_theme.dart flutter_app/lib/main.dart flutter_app/test/widgets/forest_ui_smoke_test.dart
git commit -m "feat: add shared forest theme"
```

### Task 3: Add reusable background and card shells

**Files:**
- Create: `flutter_app/lib/widgets/page_background.dart`
- Create: `flutter_app/lib/widgets/decorated_card.dart`
- Create: `flutter_app/lib/widgets/section_title.dart`
- Create: `flutter_app/lib/widgets/soft_status_badge.dart`
- Test: `flutter_app/test/widgets/forest_ui_smoke_test.dart`

- [ ] **Step 1: Write a failing widget test for shared UI primitives**

Add a test that pumps `PageBackground` + `DecoratedCard` + `SectionTitle`.

```dart
testWidgets('shared forest primitives render together', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: forestTheme,
      home: PageBackground(
        child: DecoratedCard(
          child: SectionTitle(title: '标题', subtitle: '副标题'),
        ),
      ),
    ),
  );

  expect(find.text('标题'), findsOneWidget);
  expect(find.text('副标题'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: FAIL because new widget classes are undefined

- [ ] **Step 3: Implement minimal reusable widgets**

Requirements:
- `PageBackground` supports optional top/bottom decorative images and a gradient/solid fallback
- `DecoratedCard` wraps child with consistent rounded cream card styling
- `SectionTitle` renders title + optional subtitle
- `SoftStatusBadge` renders low-contrast badge for status labels

Keep widgets small and focused.

- [ ] **Step 4: Re-run tests**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/widgets/page_background.dart flutter_app/lib/widgets/decorated_card.dart flutter_app/lib/widgets/section_title.dart flutter_app/lib/widgets/soft_status_badge.dart flutter_app/test/widgets/forest_ui_smoke_test.dart
git commit -m "feat: add shared forest ui primitives"
```

## Chunk 2: Generated illustration assets and activity cards

### Task 4: Add generated UI image assets

**Files:**
- Create: `flutter_app/assets/images/ui/*`
- Create: `flutter_app/assets/images/activities/*`
- Create: `flutter_app/lib/widgets/activity_illustration.dart`
- Test: `flutter_app/test/widgets/activity_card_test.dart`

- [ ] **Step 1: Generate and save the approved assets**

Save generated files with clear names such as:
- `assets/images/ui/splash_forest_hero.png`
- `assets/images/ui/forest_decor_top_left.png`
- `assets/images/ui/forest_decor_bottom_right.png`
- `assets/images/ui/report_finish_scene.png`
- `assets/images/activities/detective.png`
- `assets/images/activities/match.png`
- `assets/images/activities/face_build.png`
- `assets/images/activities/social.png`
- `assets/images/activities/diary.png`

- [ ] **Step 2: Write a failing test for activity illustration mapping**

In `activity_card_test.dart`, add a test for a mapping widget/class:

```dart
testWidgets('activity illustration resolves for detective', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: ActivityIllustration(activityKey: 'detective')));
  expect(find.byType(Image), findsOneWidget);
});
```

- [ ] **Step 3: Run test to verify failure**

Run: `flutter test test/widgets/activity_card_test.dart -r expanded`
Expected: FAIL because `ActivityIllustration` does not exist

- [ ] **Step 4: Implement `activity_illustration.dart`**

Map each activity key to a local asset path. Keep it simple: a small stateless widget with `Image.asset` and graceful fallback icon if key is unknown.

- [ ] **Step 5: Re-run test**

Run: `flutter test test/widgets/activity_card_test.dart -r expanded`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add flutter_app/assets/images/ui flutter_app/assets/images/activities flutter_app/lib/widgets/activity_illustration.dart flutter_app/test/widgets/activity_card_test.dart
git commit -m "feat: add forest illustration assets"
```

### Task 5: Rebuild `ActivityCard` into an illustrated story card

**Files:**
- Modify: `flutter_app/lib/widgets/activity_card.dart`
- Modify: `flutter_app/lib/widgets/activity_illustration.dart`
- Test: `flutter_app/test/widgets/activity_card_test.dart`

- [ ] **Step 1: Write a failing card structure test**

Add a test asserting:
- label text is present
- illustration widget is present
- card still responds to taps

```dart
testWidgets('activity card shows illustration and label', (tester) async {
  var tapped = false;
  await tester.pumpWidget(MaterialApp(
    home: ActivityCard(
      label: '情绪大侦探',
      emoji: '🕵️',
      color: const Color(0xFF42A5F5),
      onTap: () => tapped = true,
    ),
  ));

  expect(find.text('情绪大侦探'), findsOneWidget);
  await tester.tap(find.byType(ActivityCard));
  expect(tapped, isTrue);
});
```

- [ ] **Step 2: Run test to capture current baseline**

Run: `flutter test test/widgets/activity_card_test.dart -r expanded`
Expected: PASS or near-pass; then refine test to require new illustration structure before proceeding

- [ ] **Step 3: Update the test to require the new illustrated layout**

Require `Image` and subtitle/shape container as needed.

- [ ] **Step 4: Implement the redesigned card**

Card requirements:
- cream card background instead of solid fill block
- colored accent border / glow per activity
- generated illustration image centered or upper aligned
- label + optional small companion subtitle
- larger padding and softer shadow

- [ ] **Step 5: Re-run tests**

Run: `flutter test test/widgets/activity_card_test.dart -r expanded`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/widgets/activity_card.dart flutter_app/test/widgets/activity_card_test.dart flutter_app/lib/widgets/activity_illustration.dart
git commit -m "feat: redesign activity cards with illustrations"
```

## Chunk 3: Screen-by-screen redesign

### Task 6: Redesign Splash screen

**Files:**
- Modify: `flutter_app/lib/screens/splash_screen.dart`
- Modify: `flutter_app/lib/widgets/page_background.dart`
- Test: `flutter_app/test/widgets/forest_ui_smoke_test.dart`

- [ ] **Step 1: Write a failing smoke test for splash hierarchy**

Add assertions for:
- app title `星语灵境`
- partner selection copy
- existing children section

- [ ] **Step 2: Run test to confirm current baseline**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: PASS or partial; then tighten expectations for new structure and verify failure

- [ ] **Step 3: Implement splash redesign**

Requirements:
- wrap content in `PageBackground`
- use splash hero image prominently
- convert robot creation cards into softer illustrated choice cards
- convert existing child list into story cards / wood plaque style rows
- keep all existing create/select behaviors unchanged

- [ ] **Step 4: Re-run tests**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Manually verify in browser**

Run app and confirm splash layout works at desktop width.

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/screens/splash_screen.dart flutter_app/test/widgets/forest_ui_smoke_test.dart flutter_app/lib/widgets/page_background.dart
 git commit -m "feat: redesign splash screen as forest welcome page"
```

### Task 7: Redesign Home screen

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`
- Modify: `flutter_app/lib/widgets/activity_card.dart`
- Test: `flutter_app/test/widgets/forest_ui_smoke_test.dart`

- [ ] **Step 1: Write a failing smoke test for homepage story framing**

Assert the presence of:
- heading text
- all five activity labels
- activity cards count

- [ ] **Step 2: Run test to verify failure after tightening structure expectations**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: FAIL if expecting new title/subtitle hierarchy

- [ ] **Step 3: Implement home redesign**

Requirements:
- `PageBackground` wrapper
- welcoming title/subtitle block
- improved activity grid spacing
- reduced saturation and more storybook framing
- therapist entry remains available but less visually dominant

- [ ] **Step 4: Re-run tests**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Browser verification**

Confirm activity cards look balanced and clickable at the target viewport.

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart flutter_app/test/widgets/forest_ui_smoke_test.dart flutter_app/lib/widgets/activity_card.dart
 git commit -m "feat: redesign home screen as forest activity map"
```

### Task 8: Redesign Training screen layout

**Files:**
- Modify: `flutter_app/lib/screens/training_screen.dart`
- Modify: `flutter_app/lib/widgets/tino_robot.dart` (only if spacing/stage wrapper is needed)
- Modify: `flutter_app/lib/widgets/soft_status_badge.dart`
- Test: `flutter_app/test/widgets/forest_ui_smoke_test.dart`

- [ ] **Step 1: Write failing smoke tests for training layout landmarks**

Assert the presence of:
- question progress text
- Tino widget
- answer controls
- softened camera status container

- [ ] **Step 2: Run tests to verify failure once layout-specific expectations are added**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: FAIL for missing new structural markers

- [ ] **Step 3: Implement training shell redesign**

Requirements:
- left companion area with enlarged Tino and gentle forest stage
- right large content card for question / stimulus / answers
- low-stimulation status badge instead of intrusive warning chip
- keep existing training logic, timing, hints, submissions, and diary/match/face build flows intact
- preserve desktop usability first; do not refactor unrelated behavior

- [ ] **Step 4: Re-run tests**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Manual browser verification**

Check detective flow at desktop width and ensure Tino occupies ~20–25% of the layout without clipping.

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/screens/training_screen.dart flutter_app/lib/widgets/tino_robot.dart flutter_app/lib/widgets/soft_status_badge.dart flutter_app/test/widgets/forest_ui_smoke_test.dart
 git commit -m "feat: redesign training layout around companion robot"
```

### Task 9: Redesign Summary / report screen

**Files:**
- Modify: `flutter_app/lib/screens/summary_screen.dart`
- Modify: `flutter_app/lib/widgets/page_background.dart`
- Test: `flutter_app/test/widgets/forest_ui_smoke_test.dart`

- [ ] **Step 1: Write a failing smoke test for summary content hierarchy**

Assert the presence of:
- completion heading
- chart card title
- dominant emotion / summary copy
- home button

- [ ] **Step 2: Run tests to verify failure after structure tightening**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: FAIL for missing updated phrasing / wrappers

- [ ] **Step 3: Implement summary redesign**

Requirements:
- forest background and finish decoration
- stronger content grouping with decorated cards
- more companion-like summary wording
- keep existing chart and emotion summary logic working

- [ ] **Step 4: Re-run tests**

Run: `flutter test test/widgets/forest_ui_smoke_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Manual browser verification**

Verify the summary page still shows the line chart cleanly and feels less empty.

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/screens/summary_screen.dart flutter_app/lib/widgets/page_background.dart flutter_app/test/widgets/forest_ui_smoke_test.dart
 git commit -m "feat: redesign summary screen as storybook report"
```

## Chunk 4: Final integration and verification

### Task 10: Clean up shared copy and consistency issues

**Files:**
- Modify: any touched Flutter UI files only if needed for consistency
- Test: `flutter_app/test/widgets/forest_ui_smoke_test.dart`, `flutter_app/test/widgets/activity_card_test.dart`

- [ ] **Step 1: Run full relevant widget test suite**

Run:
```bash
flutter test test/widgets/forest_ui_smoke_test.dart test/widgets/activity_card_test.dart test/widgets/tino_robot_test.dart -r expanded
```
Expected: PASS

- [ ] **Step 2: Run broader Flutter tests if stable**

Run:
```bash
flutter test -r expanded
```
Expected: PASS or only pre-existing unrelated failures; if failures are unrelated, document them explicitly before continuing

- [ ] **Step 3: Build web bundle**

Run:
```bash
flutter build web --release
```
Expected: successful build

- [ ] **Step 4: Manually verify key pages in browser**

Check:
- `/config`
- `/splash`
- `/home`
- one training flow
- `/summary`

Validate against the spec:
- consistent forest theme
- low-stimulation visual hierarchy
- prominent Tino on training page
- better demo readiness

- [ ] **Step 5: Commit final polish**

```bash
git add flutter_app/lib flutter_app/assets flutter_app/test flutter_app/pubspec.yaml
git commit -m "feat: apply forest storybook theme across core screens"
```

---

Plan complete and saved to `docs/superpowers/plans/2026-04-30-frontend-forest-theme.md`. Ready to execute?
