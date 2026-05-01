# Training Content Upgrade Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the detective and match training content system so the two activities have distinct task models, use explicit item schemas, and support expandable storybook/3D asset pools with deterministic per-round style selection.

**Architecture:** Split the work into three layers: content schema and validation, runtime selection logic, and activity-specific UI/runtime behavior. Keep the Flutter shell and current visual theme intact while changing how questions are represented, loaded, selected, and rendered for detective vs match.

**Tech Stack:** Python backend question bank JSON + generator tooling, FastAPI backend services, Flutter frontend, Riverpod providers, flutter_test, generated PNG/scene assets.

---

## File map

### Existing files to modify
- `backend/question_bank/detective.json` — convert detective items to explicit schema and new template taxonomy
- `backend/question_bank/match.json` — convert match items to explicit schema and new template taxonomy
- `backend/question_bank/generate_questions.py` — update generator helpers for explicit item schema and style/template coverage
- `backend/question_loader.py` — load and validate the upgraded item schema
- `backend/schemas.py` — expand question/session schemas if needed for target subject, style, and match payload
- `backend/routers/...` or content-serving code that starts sessions — ensure runtime selection respects style/template availability
- `flutter_app/lib/models/question.dart` — represent explicit item schema fields on the client
- `flutter_app/lib/models/session.dart` — carry style/session metadata if needed
- `flutter_app/lib/services/api_service.dart` — parse new session/question payload fields
- `flutter_app/lib/screens/training_screen.dart` — render distinct detective vs match task behavior using explicit templates
- `flutter_app/lib/config/activity_catalog.dart` — update subtitles/copy if activity behavior changes need wording support

### New files to create
- `backend/question_bank/content_rules.json` — machine-readable required template rules and completeness thresholds per activity/level/style
- `backend/question_bank/storybook_manifest.json` — explicit asset registry for storybook training assets
- `backend/question_bank/three_d_manifest.json` — explicit asset registry for 3D training assets
- `backend/content_selection.py` — select style/template/questions per child/activity/level using completeness + rotation rules
- `backend/content_validation.py` — validate explicit item schema, linkage, and completeness
- `backend/tests/test_content_validation.py` — schema/completeness validator tests
- `backend/tests/test_content_selection.py` — style-rotation and fallback tests
- `flutter_app/test/services/content_parsing_test.dart` — parsing tests for upgraded question/session payloads
- `flutter_app/test/widgets/training_content_modes_test.dart` — widget tests covering detective vs match task differences

### Asset locations to populate
- `flutter_app/assets/images/training/storybook/...`
- `flutter_app/assets/images/training/three_d/...`
- optionally `flutter_app/assets/videos/training/...` if dynamic clip templates are introduced in first pass

### Notes on scope splitting
This spec spans multiple concerns, but they are tightly coupled enough to stay in one plan because runtime selection depends on schema, and UI behavior depends on both. The plan still phases the work so each chunk produces a testable vertical slice.

---

## Chunk 1: Lock schema and validation rules

### Task 1: Define machine-readable content rules

**Files:**
- Create: `backend/question_bank/content_rules.json`
- Test: `backend/tests/test_content_validation.py`

- [ ] **Step 1: Write the failing backend test for required template rules**

Create a test that loads `content_rules.json` and asserts it contains required template sets for:
- `detective` level 1/2/3
- `match` level 1/2/3
- completeness thresholds for each template family

```python
def test_content_rules_define_required_templates_and_thresholds():
    rules = load_rules()
    assert rules['detective']['levels']['1']['required_templates'] == ['standard_face']
    assert 'scene_to_word' in rules['match']['levels']['3']['required_templates']
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `pytest backend/tests/test_content_validation.py::test_content_rules_define_required_templates_and_thresholds -v`
Expected: FAIL because the rules file/helper does not exist yet

- [ ] **Step 3: Create `content_rules.json` with explicit required-template and threshold config**

Include:
- activities
- levels
- required templates
- per-template minimum item counts
- allowed styles
- whether template is first-pass required vs later extension

- [ ] **Step 4: Re-run the test**

Run: `pytest backend/tests/test_content_validation.py::test_content_rules_define_required_templates_and_thresholds -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/question_bank/content_rules.json backend/tests/test_content_validation.py
git commit -m "feat: define machine-readable training content rules"
```

### Task 2: Add explicit content validation module

**Files:**
- Create: `backend/content_validation.py`
- Modify: `backend/question_loader.py`
- Test: `backend/tests/test_content_validation.py`

- [ ] **Step 1: Write failing tests for explicit question item validation**

Add tests for:
- required keys exist (`item_id`, `activity_id`, `template_id`, `style_id`, `difficulty_level`, `stimulus_refs`, `correct_answer`, etc.)
- detective scene/clip items require a single target subject
- match items require `match_payload`
- invalid template/activity combinations are rejected

```python
def test_detective_scene_focus_requires_target_subject():
    item = {..., 'activity_id': 'detective', 'template_id': 'scene_focus', 'target_subject_id': None}
    with pytest.raises(ValueError):
        validate_item(item, rules)
```

- [ ] **Step 2: Run the tests to verify failure**

Run: `pytest backend/tests/test_content_validation.py -v`
Expected: FAIL because validation logic does not exist yet

- [ ] **Step 3: Implement `content_validation.py`**

Implement focused validators for:
- schema shape
- activity/template compatibility
- target subject requirements
- match payload rules
- completeness counting helpers based on preauthored usable items

- [ ] **Step 4: Hook validation into `question_loader.py`**

Ensure question loading validates data early and fails fast on bad content.

- [ ] **Step 5: Re-run tests**

Run: `pytest backend/tests/test_content_validation.py -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add backend/content_validation.py backend/question_loader.py backend/tests/test_content_validation.py
git commit -m "feat: validate explicit training content schema"
```

### Task 3: Normalize frontend/backed question models for new schema

**Files:**
- Modify: `flutter_app/lib/models/question.dart`
- Modify: `backend/schemas.py`
- Test: `flutter_app/test/services/content_parsing_test.dart`

- [ ] **Step 1: Write the failing frontend parsing test**

Add a test that parses a sample upgraded question/session payload including:
- `template_id`
- `style_id`
- `stimulus_refs`
- `target_subject_id`
- `match_payload`

```dart
test('Question parses explicit schema fields', () {
  final question = Question.fromJson(sampleJson);
  expect(question.templateId, 'expression_to_word');
  expect(question.styleId, 'storybook');
});
```

- [ ] **Step 2: Run the test to verify failure**

Run: `E:/flutter/bin/flutter.bat test test/services/content_parsing_test.dart`
Expected: FAIL because fields/models are missing

- [ ] **Step 3: Update backend and frontend models minimally**

Add only the fields needed by the spec and current renderer.

- [ ] **Step 4: Re-run the test**

Run: `E:/flutter/bin/flutter.bat test test/services/content_parsing_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/schemas.py flutter_app/lib/models/question.dart flutter_app/test/services/content_parsing_test.dart
git commit -m "feat: support explicit training item schema in models"
```

## Chunk 2: Make runtime selection deterministic

### Task 4: Add style manifests and completeness-aware selection

**Files:**
- Create: `backend/question_bank/storybook_manifest.json`
- Create: `backend/question_bank/three_d_manifest.json`
- Create: `backend/content_selection.py`
- Test: `backend/tests/test_content_selection.py`

- [ ] **Step 1: Write failing selection tests**

Cover:
- previous round style is remembered per `child_id + activity_id`
- selection prefers alternate style when both are complete
- fallback chooses the only complete style
- activity/level with no complete style is rejected

```python
def test_selection_prefers_style_different_from_previous_round():
    selected = select_round_style(previous_style='storybook', available_styles=['storybook', 'three_d'])
    assert selected == 'three_d'
```

- [ ] **Step 2: Run tests to verify failure**

Run: `pytest backend/tests/test_content_selection.py -v`
Expected: FAIL because manifests/selection logic do not exist yet

- [ ] **Step 3: Create style manifests**

Each manifest should map asset IDs to style-specific training assets and metadata.

- [ ] **Step 4: Implement `content_selection.py`**

Implement:
- completeness checks using validated items + rules
- style selection by `child_id + activity_id`
- template availability lookup
- template fallback within a locked style

- [ ] **Step 5: Re-run tests**

Run: `pytest backend/tests/test_content_selection.py -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add backend/question_bank/storybook_manifest.json backend/question_bank/three_d_manifest.json backend/content_selection.py backend/tests/test_content_selection.py
git commit -m "feat: add completeness-aware style selection"
```

### Task 5: Integrate runtime selection into session start flow

**Files:**
- Modify: backend code that starts sessions (likely router/service modules used by `startSession`)
- Modify: `flutter_app/lib/services/api_service.dart`
- Modify: `flutter_app/lib/models/session.dart`
- Test: `backend/tests/test_content_selection.py`, `flutter_app/test/services/content_parsing_test.dart`

- [ ] **Step 1: Write failing backend test for session-start style lock**

Test that starting a session returns:
- selected style ID
- first question from that style only
- template allowed for the activity

- [ ] **Step 2: Run test to verify failure**

Run: `pytest backend/tests/test_content_selection.py -v`
Expected: FAIL because session start does not expose the selection result yet

- [ ] **Step 3: Implement minimal integration**

Persist or pass forward enough round metadata so later question fetches stay inside the chosen style.

- [ ] **Step 4: Update Flutter parsing for round style/session metadata**

Only expose the fields needed by current app state.

- [ ] **Step 5: Re-run backend and frontend parsing tests**

Run:
```bash
pytest backend/tests/test_content_selection.py -v && E:/flutter/bin/flutter.bat test test/services/content_parsing_test.dart
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add backend flutter_app/lib/services/api_service.dart flutter_app/lib/models/session.dart flutter_app/test/services/content_parsing_test.dart
git commit -m "feat: lock training rounds to selected content style"
```

## Chunk 3: Actually separate detective and match behavior

### Task 6: Restructure detective question bank into explicit templates

**Files:**
- Modify: `backend/question_bank/detective.json`
- Possibly modify: `backend/question_bank/generate_questions.py`
- Test: `backend/tests/test_content_validation.py`

- [ ] **Step 1: Write failing validation tests for detective template coverage**

Cover:
- level 1 items use `standard_face`
- level 2 items use `subtle_face`
- level 3 items use `scene_focus` or `dynamic_clip`
- scene/clip items include explicit target subject fields

- [ ] **Step 2: Run test to verify failure**

Run: `pytest backend/tests/test_content_validation.py -v`
Expected: FAIL against current detective bank

- [ ] **Step 3: Convert detective bank to explicit schema**

Minimal conversion goals:
- stable `item_id`
- `activity_id = detective`
- `template_id`
- `style_id`
- `stimulus_refs`
- `target_subject_id` where required
- `correct_answer` / `distractors`

Do not overpopulate future-only metadata.

- [ ] **Step 4: Re-run validation tests**

Run: `pytest backend/tests/test_content_validation.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/question_bank/detective.json backend/question_bank/generate_questions.py backend/tests/test_content_validation.py
git commit -m "feat: normalize detective question bank templates"
```

### Task 7: Restructure match question bank into true matching templates

**Files:**
- Modify: `backend/question_bank/match.json`
- Possibly modify: `backend/question_bank/generate_questions.py`
- Test: `backend/tests/test_content_validation.py`

- [ ] **Step 1: Write failing validation tests for match template coverage**

Cover:
- level 1 uses `expression_to_word`
- level 2 uses `expression_to_scene` or `scene_to_expression`
- level 3 uses `scene_to_word`
- `match_payload` is present and direction-specific
- `triad_match` stays optional in first pass

- [ ] **Step 2: Run test to verify failure**

Run: `pytest backend/tests/test_content_validation.py -v`
Expected: FAIL against current match bank

- [ ] **Step 3: Convert match bank into genuine matching items**

For each item, explicitly encode the direction and pairing payload rather than just “stimulus + choices”.

- [ ] **Step 4: Re-run validation tests**

Run: `pytest backend/tests/test_content_validation.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/question_bank/match.json backend/question_bank/generate_questions.py backend/tests/test_content_validation.py
git commit -m "feat: rebuild match question bank around matching tasks"
```

### Task 8: Render distinct detective vs match UI behaviors in Flutter

**Files:**
- Modify: `flutter_app/lib/screens/training_screen.dart`
- Test: `flutter_app/test/widgets/training_content_modes_test.dart`

- [ ] **Step 1: Write failing widget tests for activity mode differences**

Cover:
- detective mode renders a single-stimulus recognition task
- match mode renders matching-oriented layout/content
- match mode should not regress back into plain single-judgment copy

```dart
testWidgets('match mode shows matching task framing', (tester) async {
  await tester.pumpWidget(buildTrainingScreen(activityType: 'match', question: matchQuestion));
  expect(find.textContaining('配对'), findsWidgets);
});
```

- [ ] **Step 2: Run the test to verify failure**

Run: `E:/flutter/bin/flutter.bat test test/widgets/training_content_modes_test.dart`
Expected: FAIL because the new behavior contract is not fully encoded yet

- [ ] **Step 3: Implement minimal UI changes in `training_screen.dart`**

Goals:
- detective remains “single stimulus → single judgment”
- match reads and renders `match_payload` directions explicitly
- no unrelated refactor of other activities

- [ ] **Step 4: Re-run the test**

Run: `E:/flutter/bin/flutter.bat test test/widgets/training_content_modes_test.dart`
Expected: PASS

- [ ] **Step 5: Run existing smoke tests too**

Run:
```bash
E:/flutter/bin/flutter.bat test test/widgets/forest_ui_smoke_test.dart test/widgets/activity_card_test.dart
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/screens/training_screen.dart flutter_app/test/widgets/training_content_modes_test.dart flutter_app/test/widgets/forest_ui_smoke_test.dart flutter_app/test/widgets/activity_card_test.dart
git commit -m "feat: separate detective and match training behaviors"
```

## Chunk 4: Populate enough assets to make the system real

### Task 9: Add first-pass storybook asset coverage for required templates

**Files:**
- Modify/Create: training asset directories and manifest entries
- Test: `backend/tests/test_content_selection.py`

- [ ] **Step 1: Inventory missing storybook assets per required template**

Use manifests/rules to identify exactly which required template slots are missing first-pass coverage.

- [ ] **Step 2: Generate and save first-pass storybook assets**

Follow the agreed image workflow:
- create English prompts
- generate assets via the available image interface
- review outputs
- save accepted assets with stable IDs/paths

- [ ] **Step 3: Register assets in storybook manifest**

Ensure every new asset has explicit metadata and linkage fields.

- [ ] **Step 4: Re-run completeness tests**

Run: `pytest backend/tests/test_content_selection.py -v`
Expected: PASS for required storybook coverage

- [ ] **Step 5: Commit**

```bash
git add backend/question_bank/storybook_manifest.json flutter_app/assets/images/training
 git commit -m "feat: add first-pass storybook training assets"
```

### Task 10: Add first-pass 3D asset coverage and verify rotation logic

**Files:**
- Modify/Create: `backend/question_bank/three_d_manifest.json`, training asset directories
- Test: `backend/tests/test_content_selection.py`

- [ ] **Step 1: Generate and save first-pass 3D assets for the same required template set**

Keep style parity with existing storybook coverage where possible.

- [ ] **Step 2: Register assets in the 3D manifest**

Include complete metadata/linkage.

- [ ] **Step 3: Run completeness + rotation tests**

Run: `pytest backend/tests/test_content_selection.py -v`
Expected: PASS with both styles available so alternation rules are exercised

- [ ] **Step 4: Commit**

```bash
git add backend/question_bank/three_d_manifest.json flutter_app/assets/images/training
 git commit -m "feat: add first-pass 3d training assets"
```

## Chunk 5: Final verification and handoff

### Task 11: Verify schema, runtime, UI, and build remain healthy

**Files:**
- Modify: touched files only if verification reveals real breakage
- Test: backend + Flutter suites

- [ ] **Step 1: Run full backend tests relevant to content selection/validation**

Run:
```bash
pytest backend/tests/test_content_validation.py backend/tests/test_content_selection.py -v
```
Expected: PASS

- [ ] **Step 2: Run full Flutter test suite**

Run:
```bash
cd flutter_app && E:/flutter/bin/flutter.bat test -r expanded
```
Expected: PASS

- [ ] **Step 3: Build Flutter web release**

Run:
```bash
cd flutter_app && E:/flutter/bin/flutter.bat build web --release --no-wasm-dry-run
```
Expected: successful build

- [ ] **Step 4: Manually verify key flows**

Check:
- Splash → child creation
- Home → detective
- Home → match
- Detective round maintains one style
- Match round maintains one style
- Summary still works

- [ ] **Step 5: Commit final integration polish**

```bash
git add backend flutter_app
git commit -m "feat: upgrade training content system with differentiated activities"
```

---

Plan complete and saved to `docs/superpowers/plans/2026-05-01-training-content-upgrade.md`. Ready to execute?
