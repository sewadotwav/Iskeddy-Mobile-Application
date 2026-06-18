# Iskeddy — Complete System Architecture & Agentic Build Plan

> **Stack:** Flutter 3.44+ · Dart 3.12+ · Firebase Firestore · Google Antigravity (Agent Mode)
> **Device:** Android 12 · Physical device via USB/wireless ADB
> **Scope:** Single-module · No auth · No login · No accounts · No AI chatbot · No friends

---

## 1. APP OVERVIEW

Iskeddy is a manual class schedule maker for students. Students create and manage
multiple schedules, add and edit course entries within each schedule, and view their
courses through a clean card-based list grouped by day. One schedule can be pinned as
the default, which is shown on the app's home tab filtered to the current day only. A
later phase adds AI-powered OCR to auto-plot a schedule from an uploaded image.

---

## 2. FOLDER STRUCTURE

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, theme, route definitions
├── constants/
│   ├── app_colors.dart               # 10 fixed course colors + accent color
│   ├── app_enums.dart                # ClassMode, CourseType enums
│   └── app_strings.dart              # Toast & dialogue copy
├── models/
│   ├── schedule_model.dart
│   ├── course_model.dart
│   └── meeting_time_model.dart
├── services/
│   ├── device_id_service.dart        # UUID generation + SharedPreferences
│   └── firestore_service.dart        # All Firestore CRUD
├── screens/
│   ├── screen1_default/
│   │   └── default_timetable_screen.dart      # Root tab — today's classes only
│   ├── screen2_schedules/
│   │   └── all_schedules_screen.dart           # Root tab — list + multi-select
│   └── screen3_detail/
│       └── schedule_detail_screen.dart         # Pushed screen — full schedule view
├── components/                       # Shared, reusable widget library — flat, no per-screen subfolders
│   ├── app_header.dart               # Calendar icon + "iskeddy" wordmark header
│   ├── app_pill.dart                 # Generic pill/badge (counts, status, tags)
│   ├── app_text_styles.dart          # Centralized text style definitions
│   ├── app_toast.dart                # Toast wrapper around fluttertoast
│   ├── circular_icon_button.dart     # Reusable small circular icon button
│   ├── color_picker_grid.dart        # 10-color fixed picker (2 rows of 5)
│   ├── confirm_dialog.dart           # Reusable confirmation dialogue
│   ├── course_card.dart              # Single course list item (shared)
│   ├── course_editor_sheet.dart      # Shared add/edit popup
│   ├── empty_state.dart              # Generic empty-state widget (icon, title, subtitle, optional button)
│   ├── name_schedule_dialog.dart     # Naming prompt shown when creating a schedule
│   ├── pill_button.dart              # Pill-shaped action button (Save/Create/Cancel)
│   └── schedule_card.dart            # Schedule list item — normal + multi-select modes
└── utils/
    └── time_utils.dart               # Time parsing, gap/break + stats calculation
```

---

## 3. DATA MODELS

### 3.1 MeetingTime

```dart
class MeetingTime {
  List<String> days;     // ["Mon", "Wed", "Fri"]
  String startTime;      // "08:00"  (24h HH:mm)
  String endTime;        // "09:30"
}
```

Every course, regardless of its class mode, uses `meetingTimes` to define when it
happens. Asynchronous courses are not exempt — students still block out a day/time
range for self-paced work, so the same field structure applies to all three class modes.

### 3.2 Course

```dart
class Course {
  String id;
  String title;
  String colorHex;                  // One of 10 fixed hex values (Section 6.1)
  String classMode;                 // "onsite" | "synchronous" | "asynchronous"
  String? courseType;               // "Lecture" | "Lab" | "Seminar" | "Workshop" | null
  String? instructor;
  String? roomNo;
  List<MeetingTime> meetingTimes;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 3.3 Schedule

```dart
class Schedule {
  String id;
  String name;
  bool isPinned;
  DateTime createdAt;
  DateTime updatedAt;
}
```

---

## 4. FIRESTORE SCHEMA

```
devices
└── {deviceId}
      ├── createdAt        : Timestamp
      └── schedules
            └── {scheduleId}
                  ├── id, name, isPinned, createdAt, updatedAt
                  └── courses
                        └── {courseId}
                              ├── id, title, colorHex, classMode, courseType
                              ├── instructor, roomNo, createdAt, updatedAt
                              └── meetingTimes : Array<Map{days, startTime, endTime}>
```

Identity is a UUID generated on first app launch and stored in SharedPreferences — no
authentication, no login. The UUID is the Firestore document ID under `devices/`.

---

## 5. FIRESTORE SECURITY RULES

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function has(data, field) {
      return field in data;
    }

    function isNonEmptyString(data, field) {
      return has(data, field)
          && data[field] is string
          && data[field].size() > 0;
    }

    function isBool(data, field) {
      return has(data, field) && data[field] is bool;
    }

    function isTimestamp(data, field) {
      return has(data, field) && data[field] is timestamp;
    }

    function isList(data, field) {
      return has(data, field) && data[field] is list;
    }

    function isValidClassMode(data) {
      return isNonEmptyString(data, 'classMode')
          && data.classMode in ['onsite', 'synchronous', 'asynchronous'];
    }

    function isValidCourseType(data) {
      return !has(data, 'courseType')
          || data.courseType == null
          || data.courseType in ['Lecture', 'Lab', 'Seminar', 'Workshop'];
    }

    function isValidColorHex(data) {
      return isNonEmptyString(data, 'colorHex')
          && data.colorHex.size() == 7
          && data.colorHex[0] == '#';
    }

    function isOptionalString(data, field) {
      return !has(data, field)
          || data[field] == null
          || data[field] is string;
    }

    function isValidSchedule(data) {
      return isNonEmptyString(data, 'id')
          && isNonEmptyString(data, 'name')
          && isBool(data, 'isPinned')
          && isTimestamp(data, 'createdAt')
          && isTimestamp(data, 'updatedAt');
    }

    function isValidCourse(data) {
      return isNonEmptyString(data, 'id')
          && isNonEmptyString(data, 'title')
          && isValidColorHex(data)
          && isValidClassMode(data)
          && isValidCourseType(data)
          && isList(data, 'meetingTimes')
          && isOptionalString(data, 'instructor')
          && isOptionalString(data, 'roomNo')
          && isOptionalString(data, 'courseType')
          && isTimestamp(data, 'createdAt')
          && isTimestamp(data, 'updatedAt');
    }

    match /devices/{deviceId} {
      allow read:   if true;
      allow create: if isTimestamp(request.resource.data, 'createdAt');
      allow update: if false;
      allow delete: if false;

      match /schedules/{scheduleId} {
        allow read:   if true;
        allow create: if isValidSchedule(request.resource.data);
        allow update: if isValidSchedule(request.resource.data);
        allow delete: if true;

        match /courses/{courseId} {
          allow read:   if true;
          allow create: if isValidCourse(request.resource.data);
          allow update: if isValidCourse(request.resource.data);
          allow delete: if true;
        }
      }
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 6. CONSTANTS

### 6.1 Fixed Course Color Palette (10 colors)

Shown as 2 rows of 5 circular swatches in the Course Editor.

| # | Name | Hex |
|---|---|---|
| 1 | Lavender | `#CDC5FA` |
| 2 | Mint / Seafoam | `#BDDBD9` |
| 3 | Sky Blue | `#C4E6FF` |
| 4 | Khaki / Olive Light | `#E4E0B6` |
| 5 | Orchid Pink | `#F9CFFF` |
| 6 | Pale Yellow | `#FDF6A8` |
| 7 | Peach | `#FFE8C4` |
| 8 | Rosy Tan | `#E4BEAB` |
| 9 | Pink | `#FDBDD2` |
| 10 | Light Green | `#BEE89D` |

A course's selected color fills its card background throughout the app (Screen 1,
Screen 3, and anywhere else a course appears).

### 6.2 Primary Accent Color

| Name | Hex | Usage |
|---|---|---|
| Ink Black | `#040505` | All primary buttons, active bottom-nav state, bold headers, selected-state rings/borders, primary icons |

- **Background:** White (`#FFFFFF`) everywhere — screens, cards, sheets, dialogs, toasts.
- **Secondary text:** Neutral mid-gray for subtitles, helper text, placeholders, and
  inactive pill text.

### 6.3 Class Mode Options (Dropdown)

| Display Label | Firestore Value |
|---|---|
| Onsite | `onsite` |
| Synchronous | `synchronous` |
| Asynchronous | `asynchronous` |

Selecting any class mode keeps the Days / Start Time / End Time fields visible in the
Course Editor — class mode never hides or changes which fields are required.

### 6.4 Course Type Options (Dropdown, nullable)

- Lecture
- Lab
- Seminar
- Workshop

---

## 7. REUSABLE COMPONENT LIBRARY

These are built once and shared across every screen rather than rebuilt per-screen.
Building them early (Phase 2–4) pays off across the rest of the app. All of them live
under the flat `lib/components/` folder — there are no per-screen widget subfolders.

| Component | File | Used In | Notes |
|---|---|---|---|
| `AppHeader` | `components/app_header.dart` | Screen 1, Screen 2 | Small calendar icon + "iskeddy" wordmark, centered. One shared header instead of duplicating the markup on both root tabs. |
| `ConfirmDialog` | `components/confirm_dialog.dart` | Delete schedule, bulk delete, delete course | Takes title, message, confirm label, and an `onConfirm` callback. White card, pill buttons. |
| `NameScheduleDialog` | `components/name_schedule_dialog.dart` | Screen 2 FAB, schedule rename | Single text field + Cancel/Create (or Save) buttons. Reused for both creating and renaming, just with different titles/labels. |
| `CourseEditorSheet` | `components/course_editor_sheet.dart` | Screen 3 (add + edit course) | One widget, two modes driven by whether a `Course?` is passed in. |
| `ColorPickerGrid` | `components/color_picker_grid.dart` | Course Editor | 10 swatches, 2 rows of 5, selection ring + checkmark. |
| `CourseCard` | `components/course_card.dart` | Screen 1, Screen 3 | Solid color fill from `colorHex`, pencil icon, title, time row, room row. |
| `ScheduleCard` | `components/schedule_card.dart` | Screen 2 | Handles both normal mode (trash icon) and multi-select mode (checkbox circle) via a prop. |
| `AppPill` | `components/app_pill.dart` | Course count badges, schedule count badge, "Active Schedule" status, day toggles, class-mode tags | One generic pill widget — fill color, text, optional icon, optional selected state — parameterized rather than rebuilt per use case. |
| `PillButton` | `components/pill_button.dart` | "Save Course", "Create"/"Save" (NameScheduleDialog), "Cancel"/"Delete" (ConfirmDialog) | One generic full-width or inline pill-shaped button — fill color, label, onTap — instead of hand-styling buttons per sheet/dialog. |
| `AppTextStyles` | `components/app_text_styles.dart` | Every screen and component | Centralized `TextStyle` constants (bold black titles, gray subtext, pill labels) so typography stays consistent without repeating style objects at every call site. |
| `CircularIconButton` | `components/circular_icon_button.dart` | Pin icon, pencil icon, FABs, close (X) button, trash icon | Generic small circular tap target — fill color, icon, size, onTap. |
| `AppToast` | `components/app_toast.dart` | Every toast trigger in Section 13 | Thin wrapper around `fluttertoast` so styling/positioning stays consistent everywhere instead of repeating config at every call site. |
| `BreakDivider` | inline in `course_card.dart` or its own small widget | Screen 1, Screen 3 lists | Small centered gray pill reading "Break", inserted by the list-building logic in `time_utils.dart`. |
| `EmptyState` | `components/empty_state.dart` | Screen 1 (no pinned / no classes today), Screen 2 (no schedules), Screen 3 (no courses) | One generic widget — icon, title, optional subtitle, optional button — instead of four separate hand-built empty screens. |

---

## 8. NAVIGATION MODEL

- **Screen 1** and **Screen 2** are root tabs under a persistent bottom navigation bar
  (`IndexedStack`).
- **Screen 3** is reached only by tapping a schedule card on Screen 2. It is pushed via
  `Navigator.push`, hides the bottom navigation bar, and shows a back arrow instead.

### Bottom Navigation Bar (Screens 1 & 2 only)

| Position | Icon | Tab |
|---|---|---|
| Left | Document/list icon | All Schedules (Screen 2) |
| Right | Pin icon | Default Timetable (Screen 1) |

Active tab: black (`#040505`) filled circle behind the icon, white icon. Inactive tab:
plain gray icon, no fill.

---

## 9. SCREEN 1 — DEFAULT TIMETABLE (root tab, read-only)

Shows the pinned schedule's courses for **today's actual date only** — there is no day
browser or tab selector on this screen.

**Layout, top to bottom:**
1. `AppHeader` — small calendar icon + "iskeddy" wordmark, centered
2. Pinned schedule's name, bold, large
3. A flat list of `CourseCard` widgets for every course whose `meetingTimes.days`
   includes today's weekday, sorted by `startTime` ascending. Asynchronous courses are
   included in this list exactly like any other course, since they carry real day/time
   data.
4. A `BreakDivider` is inserted between two consecutive cards whenever the gap between
   them is 30 minutes or more.
5. Read-only — tapping a course card does nothing.

**Empty state — no pinned schedule:**
- `EmptyState`: pin icon, "No default schedule set.", "Pin one from your schedules.",
  button "Go to Schedules" → switches the active bottom tab to Screen 2

**Empty state — pinned schedule has no classes today:**
- `EmptyState` with no button: "No classes scheduled for today."

---

## 10. SCREEN 2 — ALL SCHEDULES (root tab)

### Normal Mode

1. `AppHeader` — small calendar icon + "iskeddy" wordmark, centered
2. "Your Schedules" bold large text + `AppPill` showing "[N] SCHEDULES"
3. Vertical list of `ScheduleCard` widgets:
   - Left: small rounded-square badge with a calendar icon, pastel fill
   - Schedule name, bold black — a small pin glyph appears beside the name if
     `isPinned == true`
   - `AppPill` showing "[N] COURSES" beneath the name
   - Right side: a single trash icon button — opens `ConfirmDialog`, then deletes on
     confirm and shows a toast. No swipe gestures anywhere.
4. Long-pressing any card enters multi-select mode.
5. Bottom-right FAB: black filled circle with a plus icon → opens `NameScheduleDialog`
   (Section 12).
6. Empty state (zero schedules): `EmptyState` — "No schedules yet. Tap + to create one."

### Multi-Select Mode

- Header is replaced with: back/cancel arrow (left) → "[N] selected" (center) → trash
  icon (right, opens the bulk `ConfirmDialog`)
- Each `ScheduleCard`'s trash icon is replaced by a selection circle: hollow gray
  outline when unselected, black filled with a white checkmark when selected
- Selected cards get a black border added around the card
- The bottom navigation bar stays visible
- Tapping the back arrow, or the system back gesture, exits multi-select mode

---

## 11. SCREEN 3 — SCHEDULE DETAIL (pushed screen, editable)

Reached by tapping any schedule card on Screen 2.

**Layout, top to bottom:**
1. Back arrow (top-left) → returns to Screen 2. The bottom navigation bar is hidden.
2. Schedule name, bold, large — followed immediately by two `CircularIconButton`s:
   - **Pin icon** — toggles `isPinned`. If another schedule is currently pinned, it is
     unpinned first. Shows a toast either way.
   - **Pencil icon** — opens `NameScheduleDialog` in rename mode (text field prefilled
     with the current name) → calls `updateScheduleName` → shows a toast.
3. Subtitle line: "Active Schedule · [N] Courses" if `isPinned == true`, otherwise just
   "[N] Courses".
4. Two stat cards side by side — **only shown once the schedule has at least one
   course; hidden entirely on an empty schedule**:
   - "TOTAL HOURS" — sum of all course durations across the week, displayed as
     "X hrs / wk"
   - "CLASS DAYS" — count of distinct weekdays that have at least one course,
     displayed as "X Days"
5. A vertical list grouped by weekday section headers (MONDAY, TUESDAY, … SUNDAY).
   Days with zero courses are skipped entirely — only days with at least one course get
   a header. Within each day's section, courses are sorted by `startTime` ascending,
   with a `BreakDivider` inserted wherever the gap between two consecutive courses is
   30 minutes or more. A course that meets on multiple days (e.g. Mon/Wed) appears as a
   separate `CourseCard` under each of those day sections.
6. Tapping a course card opens `CourseEditorSheet` in Edit mode, prefilled.
7. Bottom-right FAB: black filled circle with a plus icon → opens `CourseEditorSheet`
   in Add mode. This is the only way to add a course from this screen.

There is no delete-schedule action on this screen — deleting a schedule is only
available from Screen 2.

**Empty state — schedule has zero courses:**
- Stat cards are hidden
- `EmptyState`: "No courses yet.", "Tap + to add your first course."

---

## 12. NEW SCHEDULE CREATION FLOW

1. Student taps the FAB on Screen 2.
2. `NameScheduleDialog` appears: a text field (placeholder e.g. "e.g. Fall Semester
   2024") with Cancel / Create buttons. The title cannot be empty to proceed.
3. On Create: calls `createSchedule(deviceId, name)`, then navigates to Screen 3 for the
   new schedule — which opens directly into its empty state.
4. The student manually taps the FAB on Screen 3 to begin adding courses one at a time.
   Nothing is auto-opened for them.

---

## 13. TOASTS & CONFIRMATIONS

### Toasts (via `AppToast`, auto-dismiss, non-blocking)

| Trigger | Message |
|---|---|
| Schedule created | "Schedule created" |
| Schedule renamed | "Schedule renamed" |
| Schedule pinned | "Set as default timetable" |
| Schedule unpinned | "Default timetable removed" |
| Course added | "[Course Title] added" |
| Course saved (edit) | "Changes saved" |
| Single schedule deleted | "Schedule deleted" |
| Bulk schedules deleted | "[N] schedules deleted" |
| Course deleted | "[Course Title] removed" |

### Confirmation Dialogues (via `ConfirmDialog`)

| Trigger | Title | Message |
|---|---|---|
| Delete single schedule | "Delete this schedule?" | "This cannot be undone. All courses within this schedule will be permanently removed." |
| Bulk delete | "Delete [N] schedules?" | "This cannot be undone. All courses within these schedules will be permanently removed." |
| Delete course | "Remove [Course Title]?" | "This cannot be undone." |

**Dialog style:** white rounded card, bold black title, gray subtext, two `PillButton`s
side-by-side — "Cancel" (light gray fill, black text) and "Delete" (solid black fill,
white text).

---

## 14. COURSE CARD (shared widget — Screens 1 & 3)

- Card background is filled with the course's own `colorHex` (a solid pastel fill, not
  just a border)
- Rounded corners (~20px)
- Top-right corner: a small pencil/edit icon — tapping it opens `CourseEditorSheet` in
  Edit mode for that course
- Course title: bold black, wraps to 2 lines if needed
- Time row: small clock icon + start–end time range
- Room row: small location-pin icon + room text (omitted if `roomNo` is null)
- A small class-mode `AppPill` (e.g. "Asynchronous") may appear on the card so students
  can distinguish self-paced blocks from live classes at a glance

---

## 15. COURSE EDITOR (bottom sheet, shared add/edit)

Opened only from Screen 3 — either via its FAB (Add mode) or by tapping an existing
course card (Edit mode).

**Header:** "Add Course" / "Edit Course" bold black, `CircularIconButton` close (X)
top-right.

**Fields, top to bottom:**

| Field | Type | Notes |
|---|---|---|
| Course Title | Text input | Required |
| Course Color | `ColorPickerGrid` — 10 circular swatches, 2 rows of 5 | Selected swatch shows a black ring + checkmark. Default: first color. |
| Class Mode | Dropdown | Onsite / Synchronous / Asynchronous |
| Course Type | Dropdown (nullable, side-by-side with Class Mode) | Lecture / Lab / Seminar / Workshop / None |
| Days | 7 circular single-letter toggles (M T W T F S S) | Black fill + white letter when selected |
| Start Time / End Time | Two pill fields side-by-side | Opens native time picker |
| + Add another meeting time | Text link with plus icon | Adds another Days/Start/End block, each with its own remove icon once more than one exists |
| Instructor | Text input (side-by-side with Room No.) | Optional |
| Room No. | Text input | Optional |

The Days / Start Time / End Time fields are always visible, regardless of which class
mode is selected — asynchronous courses still need a day/time block, since students use
it to schedule their self-paced work.

**Bottom actions:**
- **"Save Course"** — `PillButton`, full-width black pill, bold white text. Validates the
  title is non-empty before saving.
- **"Delete"** — text-only link below Save, shown in Edit mode only. Opens
  `ConfirmDialog`: "Remove [Course Title]? This cannot be undone."

---

## 16. COURSE LIST & GROUPING LOGIC

There is no calendar grid anywhere in the app. All course display is built from two
list-building functions in `time_utils.dart`:

1. **Today list (Screen 1):** filter all of the pinned schedule's courses to those whose
   `meetingTimes.days` contains today's weekday, flatten to one card per matching
   meeting time, sort by `startTime`, insert `BreakDivider`s for gaps ≥ 30 minutes.

2. **Grouped-by-day list (Screen 3):** for each weekday Monday through Sunday, filter
   the schedule's courses to those whose `meetingTimes.days` contains that weekday.
   Skip the weekday entirely if no courses match. Within a matching weekday, sort by
   `startTime` and insert `BreakDivider`s for gaps ≥ 30 minutes, same as above.

3. **Stats calculation (Screen 3):**
   - `Total Hours` = sum of (`endTime` − `startTime`) across every meeting time in the
     schedule, displayed per week.
   - `Class Days` = count of distinct weekdays that have at least one course.

No overlap/conflict-resolution logic is needed, since courses render as sequential
cards in a vertical list rather than positioned on a grid.

---

## 17. PACKAGES (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: latest
  cloud_firestore: latest
  shared_preferences: latest
  uuid: latest
  intl: latest
  fluttertoast: latest
  dropdown_button2: latest
```

---

## 18. AGENTS.md (place in project root)

```markdown
# Iskeddy — Agent Rules

## Project
Flutter 3.44 + Dart 3.12 + Firebase Firestore app.
Single-module. No auth. No login. No accounts.
Target: Android 12 physical device.

## UI Model
- There is no calendar grid anywhere in this app.
- Screen 1 shows a flat list of today's courses only (pinned schedule, read-only).
- Screen 3 shows a full list grouped under weekday section headers, skipping empty days.
- Screen 1 and Screen 2 are root tabs (bottom nav visible, IndexedStack).
- Screen 3 is a pushed screen (Navigator.push) — bottom nav hidden, back arrow shown.

## Architecture
- lib/ structure defined in ISKEDDY_SYSTEM_ARCHITECTURE.md
- All Firestore ops go through lib/services/firestore_service.dart only
- No business logic in UI widgets
- Models are plain Dart classes with .toMap() and .fromMap() methods
- All shared widgets live under lib/components/ (flat — no per-screen widget
  subfolders); reuse the shared component library (Section 7) — do not hand-build a
  one-off pill, dialog, card, or button when a shared component already covers it

## Constants
- Course colors: 10 fixed hex values only (see app_colors.dart)
- Primary accent/text color: #040505
- Class modes: onsite (label "Onsite"), synchronous, asynchronous
- Course types: Lecture, Lab, Seminar, Workshop (all nullable)

## Rules
- Never use swipe-to-delete anywhere — always an explicit icon/button
- All delete actions require a confirmation dialogue first
- All major user actions show a toast after completion
- isPinned: true must only exist on one schedule at a time — unpin others before pinning new
- Class mode never hides any Course Editor fields — Days/Start/End stay visible for all three modes
- Course Editor is a shared widget used for both add and edit modes
- Course cards use the course's own colorHex as a solid background fill
- Bottom nav stays visible during Screen 2 multi-select mode — do not hide it
- Bottom nav is hidden on Screen 3 — it is a pushed screen with a back arrow
- New schedules are created through a naming dialog, never with a default placeholder name
```

---

## 19. BUILD PLAN

### Phase 1 — Foundation
| Batch | Task | Status |
|---|---|---|
| 1 | Project init, Firebase, pub get, flutterfire configure, offline persistence | Complete |
| 2 | Constants & enums | Complete (final code in Section 20) |
| 3 | Data models (MeetingTime, Course, Schedule) | Complete |
| 4 | Device ID service + test | Complete |
| 5 | Firestore service (all CRUD methods) | Complete |

### Phase 2 — Navigation Shell
**Batch 6** — App shell & bottom navigation
1. Create `lib/app.dart` with `MaterialApp`, named routes for Screen 1, Screen 2, Screen 3
2. Build the 2-tab bottom navigation bar with `IndexedStack` wrapping Screen 1 and Screen 2
3. Screen 3 registered as a pushed route, not a tab
4. Placeholder screens for all three, confirm navigation works on device

### Phase 3 — Shared Components (lib/components/)
**Batch 7** — `AppHeader`, `AppPill`, `AppTextStyles`, `CircularIconButton`, | Complete |
`ConfirmDialog`, `AppToast`, `PillButton` — build these generic widgets first since
every later screen depends on them

**Batch 8** — `ColorPickerGrid` (10 swatches, 2 rows of 5) and `EmptyState` | Complete |

### Phase 4 — Screen 2 (All Schedules)
**Batch 9** — `ScheduleCard` (in `lib/components/`, not a screen-scoped subfolder):
badge icon, name, course count pill, pin glyph, trash icon (normal mode) / selection
circle (multi-select mode)

**Batch 10** — All Schedules screen: StreamBuilder, normal/multi-select state toggling,
header swap, empty state

**Batch 11** — `NameScheduleDialog` (in `lib/components/`) + FAB wiring: opens dialog →
`createSchedule` → navigate to empty Screen 3

**Batch 12** — Individual delete + bulk delete wiring using `ConfirmDialog`

### Phase 5 — Course Editor
**Batch 13** — `CourseEditorSheet` (in `lib/components/`): all fields in the order
specified in Section 15, Days/Start/End always visible regardless of class mode

**Batch 14** — Meeting times subsection: add/remove multiple meeting-time blocks

### Phase 6 — Course List & Grouping Logic
**Batch 15** — `time_utils.dart`: time parsing, gap/break detection (≥30 min), total
weekly hours calculation, distinct class-days calculation

**Batch 16** — `CourseCard` widget: solid color fill, pencil icon, title, time row,
room row, class-mode pill

**Batch 17** — Grouped-by-day list builder for Screen 3 (skips empty weekdays)

**Batch 18** — Today-filtered list builder for Screen 1

### Phase 7 — Screen 3 (Schedule Detail)
**Batch 19** — Screen shell: back arrow, name + pin + pencil icons, subtitle, stat
cards (hidden if empty), grouped list, FAB, empty state

**Batch 20** — Pin/rename wiring: pin icon toggles `isPinned` + toast; pencil icon opens
`NameScheduleDialog` in rename mode + toast

**Batch 21** — Course tap → `CourseEditorSheet` (Edit mode); FAB → `CourseEditorSheet`
(Add mode)

### Phase 8 — Screen 1 (Default Timetable)
**Batch 22** — Screen shell: fetch pinned schedule, render today-filtered list, both
empty states (no pinned schedule / no classes today)

### Phase 9 — Polish & Edge Cases
**Batch 23** — Toast integration audit across every action in Section 13

**Batch 24** — Edge cases: empty rename defaults to "Untitled Schedule", pinned schedule
deleted while viewing Screen 1, long course titles, end time ≤ start time validation,
multi-select exit behavior

**Batch 25** — Final integration test on physical device: full create → add courses →
pin → edit → delete flow, confirm Firestore offline + online persistence

### Phase 10 — OCR Import (post-launch)
**Batch 26** — OCR screen shell + bottom nav third tab

**Batch 27** — Image picker integration (camera/gallery, preview)

**Batch 28** — Gemini Flash multimodal call, parse JSON response into draft courses

**Batch 29** — Draft review screen, editable list, save as new schedule, toast

---

*End of Iskeddy System Architecture.*