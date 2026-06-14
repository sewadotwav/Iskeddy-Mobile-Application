# Iskeddy — Complete System Architecture & Agentic Build Plan

> **Stack:** Flutter 3.44+ · Dart 3.12+ · Firebase Firestore · Google Antigravity (Agent Mode)
> **Device:** Android 12 · Physical device via USB/wireless ADB
> **Scope:** Single-module · No auth · No login · No accounts · No AI chatbot · No friends

---

## 1. APP OVERVIEW

Iskeddy is a manual class schedule maker for students. Students create and manage multiple weekly timetable sets, add and edit course entries per schedule, and view them in a portrait-first Mon–Sun grid. A second phase adds AI-powered OCR to auto-plot a schedule from an uploaded image.

---

## 2. FOLDER STRUCTURE

```
lib/
├── main.dart
├── app.dart                        # MaterialApp, theme, bottom nav shell
├── constants/
│   ├── app_colors.dart             # 9 fixed course colors + app palette
│   └── app_enums.dart              # ClassMode, CourseType enums
├── models/
│   ├── schedule_model.dart
│   ├── course_model.dart
│   └── meeting_time_model.dart
├── services/
│   ├── device_id_service.dart      # UUID generation + SharedPreferences
│   └── firestore_service.dart      # All Firestore CRUD
├── screens/
│   ├── screen1_default/
│   │   └── default_timetable_screen.dart
│   ├── screen2_schedules/
│   │   ├── all_schedules_screen.dart
│   │   └── widgets/
│   │       └── schedule_card.dart
│   └── screen3_detail/
│       ├── schedule_detail_screen.dart
│       └── widgets/
│           ├── timetable_grid.dart
│           └── time_block.dart
├── widgets/
│   ├── course_editor_sheet.dart    # Shared add/edit popup
│   ├── confirm_dialog.dart         # Reusable confirmation dialogue
│   └── color_picker_row.dart       # 9-color fixed picker
└── utils/
    └── time_utils.dart             # Time parsing, overlap detection
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

### 3.2 Course

```dart
class Course {
  String id;                        // UUID
  String title;                     // Required
  String colorHex;                  // One of 9 fixed hex values
  String classMode;                 // "onsite" | "synchronous" | "asynchronous"
  String? courseType;               // "Lecture" | "Lab" | "Recitation" | "Seminar" | "Workshop" | null
  String? instructor;               // Optional
  String? roomNo;                   // Optional
  List<MeetingTime> meetingTimes;   // Empty list allowed (valid for async)
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 3.3 Schedule

```dart
class Schedule {
  String id;            // UUID
  String name;          // e.g. "Sem 1 - 2026"
  bool isPinned;        // Only one schedule can be true at a time
  DateTime createdAt;
  DateTime updatedAt;
  // courses loaded as subcollection, not embedded
}
```

---

## 4. FIRESTORE SCHEMA

```
courses/{courseId}
├── id : String
├── title : String
├── colorHex : String
├── classMode : String (free text, course default)
├── courseType : String (nullable, free text, course default)
├── instructor : String (nullable)
├── roomNo : String (nullable, course default)
├── createdAt : Timestamp
├── updatedAt : Timestamp
└── meetingTimes : Array<Map>
      └── [
            {
              days : Array<String>,
              startTime : String,
              endTime : String,
              classMode : String (nullable, overrides course default),
              courseType : String (nullable, overrides course default),
              roomNo : String (nullable, overrides course default)
            }
          ]
```

**Rules:**
- `isPinned: true` → enforced to only one document per device in app logic
- `meetingTimes` is an Array of Maps (not subcollection) — always fetched with its course
- Async classMode → `meetingTimes` may be an empty array, which is valid
- Firestore offline persistence enabled globally at app init

---

## 5. CONSTANTS

### 5.1 Fixed Color Palette (9 colors)

| Name       | Hex       |
|------------|-----------|
| Light Orange  | `#f9e9d0` |
| Pastel Orange| `#ffc498` |
| Gray Orange| `#c5ab93` |
| Light  Yellow | `#feeda8` |
| Pastel Gray Turquioise     | `#b7cbc9` |
| Light Red| `#FFA726` |
| Pastel Gray Lavender| `#c0b7cb` |
| pastel gray yellow green| `#c6d899` |
| Light Red| `#ffacac` |

### 5.2 Class Mode Options (Dropdown)

- Onsite
- Synchronous
- Asynchronous

### 5.3 Course Type Options (Dropdown, nullable)

- Lecture
- Lab
- Seminar
- Workshop

---

## 6. SCREENS & NAVIGATION

### Bottom Navigation Bar

```
Tab 1: Screen 1 — Default Timetable   
Tab 2: Screen 2 — All Schedules      
```

---

### Screen 1 — Default Timetable

- Displays the pinned schedule's full timetable grid
- Read-only (no editing from this screen)
- If nothing is pinned: empty state — "No default schedule set. Pin one from your schedules."
- Portrait-first weekly grid
- Y-axis: time slots (configurable range, e.g. 7:30 AM – 9:30 PM, 30-min intervals)
- X-axis: Mon → Sun, horizontal scroll if all 7 days don't fit on screen

---

### Screen 2 — All Schedules

- Horizontal card-style scroll list of all schedules
- Each card displays:
  - Schedule name
  - Number of courses
  - Pin indicator if isPinned
  - 🗑️ delete icon (top-right of card)
- **Single tap** → navigates to Screen 3
- **Delete icon tap** → confirmation dialogue → toast on confirm
- **Long press** → enters multi-select mode:
  - Checkboxes appear on all cards
  - App bar changes to show selected count + bulk delete button
  - Tapping outside or pressing back exits multi-select
- **Bulk delete** → confirmation dialogue → toast on confirm
- **Bottom-right circular FAB** → creates a new blank schedule with a default name ("New Schedule") → navigates directly to Screen 3 with the Course Editor already open

---

### Screen 3 — Schedule Detail

- Full timetable grid for the opened schedule (same grid as Screen 1)
- **Top app bar — icons only (no text labels):**

| Icon | Action |
|------|--------|
| 📌  | Pin as default (toggle). If already pinned, unpins. Existing pinned schedule gets unpinned first. |
| ✏️  | Rename schedule — inline text field or small rename dialog |
| ➕  | Open Course Editor in Add mode |
| 🗑️  | Delete this schedule — confirmation dialogue → navigate back to Screen 2 → toast |

- **Tap a course block on the grid** → opens Course Editor in Edit mode for that course
- Empty grid state: prompt "Tap ➕ to add your first course"

---

### Course Editor (Bottom Sheet / Popup)

Shared widget used in both Add and Edit modes. Appears from Screen 3 only.

**Fields:**

| Field | Type | Notes |
|-------|------|-------|
| Course Title | Text input | Required. Cannot save if empty. |
| Color | 9 fixed color circles | Tappable, checkmark on selected. Default: first color. |
| Class Mode | Dropdown | Onsite / Synchronous / Asynchronous |
| Course Type | Dropdown (nullable) | Lecture / Lab / Recitation / Seminar / Workshop. Optional. |
| Meeting Times | Day checkboxes + time pickers | Hidden entirely when Asynchronous is selected |
| + Add Another Meeting Time | Button | Adds a new meeting time row |
| Instructor | Text input | Optional |
| Room No. | Text input | Optional |
| Save | Primary button | Validates title is non-empty before saving |
| Delete | Secondary/text button | Shown in Edit mode only. Triggers confirmation dialogue. |

---

## 7. TOASTS & CONFIRMATIONS

### Toasts (auto-dismiss, non-blocking)

| Trigger | Message |
|---------|---------|
| Schedule created | "Schedule created" |
| Schedule renamed | "Schedule renamed" |
| Schedule pinned | "Set as default timetable" |
| Schedule unpinned | "Default timetable removed" |
| Course added | "[Course Title] added" |
| Course saved (edit) | "Changes saved" |
| Single schedule deleted | "Schedule deleted" |
| Bulk schedules deleted | "[N] schedules deleted" |
| Course deleted | "[Course Title] removed" |

### Confirmation Dialogues (modal, must confirm or cancel)

| Trigger | Message |
|---------|---------|
| Delete single schedule (card icon) | "Delete this schedule? This cannot be undone." → Cancel / Delete |
| Delete schedule (Screen 3 icon) | "Delete this schedule? This cannot be undone." → Cancel / Delete |
| Bulk delete | "Delete [N] schedules? This cannot be undone." → Cancel / Delete |
| Delete course | "Remove [Course Title] from this schedule? This cannot be undone." → Cancel / Remove |

---

## 8. TIMETABLE GRID SPECIFICATION

- Custom Flutter widget built with `CustomPaint` or `Stack` + `Positioned`
- Y-axis: time labels (e.g. 7 AM, 7:30, 8 AM...), configurable start/end
- X-axis: day column headers (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
- Horizontal scroll via `SingleChildScrollView(scrollDirection: Axis.horizontal)`
- Each course block:
  - Positioned by startTime and endTime
  - Colored with its assigned colorHex
  - Displays course title (truncated if needed) in white text
  - Rounded corners
  - Tappable
- Asynchronous courses: displayed as a separate non-time-based list below the grid or labeled "Async" in a fixed row
- Conflict/overlap detection: if two courses overlap on the same day, show both blocks side by side at reduced width (no silent overwrite)

---

## 9. PACKAGES (pubspec.yaml)

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

## 10. GLOBAL CLI SETUP (one-time, before first batch)

```bash
# 1. Install Flutter SDK 3.44+
# 2. Install Android Studio (for SDK tools only)
# 3. Install Node.js, then:
npm install -g firebase-tools
# 4. Activate FlutterFire CLI:
dart pub global activate flutterfire_cli
# 5. Login and configure:
firebase login
flutterfire configure
# 6. Verify environment:
flutter doctor
```

---

## 11. AGENTS.md (place in project root before starting)

```markdown
# Iskeddy — Agent Rules

## Project
Flutter 3.44 + Dart 3.12 + Firebase Firestore app.
Single-module. No auth. No login. No accounts.
Target: Android 12 physical device.

## Architecture
- lib/ structure defined in Iskeddy_SYSTEM_ARCHITECTURE.md
- All Firestore ops go through lib/services/firestore_service.dart only
- No business logic in UI widgets
- Models are plain Dart classes with .toMap() and .fromMap() methods

## Constants
- Course colors: 9 fixed hex values only (see app_colors.dart)
- Class modes: onsite, synchronous, asynchronous
- Course types: Lecture, Lab, Seminar, Workshop (all nullable)

## Rules
- Never use swipe-to-delete anywhere
- All delete actions require a confirmation dialogue first
- All major user actions show a fluttertoast after completion
- isPinned: true must only exist on one schedule at a time — unpin others before pinning new
- Asynchronous classMode hides meetingTimes fields in the editor entirely
- Timetable grid uses horizontal scroll for Mon–Sun
- Top bar on Screen 3 uses icons only — no text labels
- Course Editor is a shared widget used for both add and edit modes
- Overlap detection: render conflicting blocks side by side, never overwrite
```

---

---

# PHASE 1 — FOUNDATION
> Goal: Project compiles, Firebase connects, models and services are ready. No UI yet.

---

## BATCH 1 — Project Initialization

1. Create new Flutter project named Iskeddy
2. Add all dependencies to `pubspec.yaml` (firebase_core, cloud_firestore, shared_preferences, uuid, intl, fluttertoast, dropdown_button2)
3. Run `flutter pub get`
4. Run `flutterfire configure` to connect to Firebase project
5. Enable Firestore offline persistence in `main.dart` using `FirebaseFirestore.instance.settings`
6. Verify app compiles and runs with default Flutter counter screen (confirm device is connected)

---

## BATCH 2 — Constants & Enums

1. Create `lib/constants/app_colors.dart`
   - Define `courseColors` as a fixed `List<Color>` of 9 hex values
   - Define app-level palette colors (background, surface, text)
2. Create `lib/constants/app_enums.dart`
   - Define `ClassMode` enum: onsite, synchronous, asynchronous
   - Define `CourseType` enum: lecture, lab, recitation, seminar, workshop
   - Add `.label` getter to each enum for display strings
3. Create `lib/constants/app_strings.dart`
   - All toast messages and confirmation dialogue strings as constants

---

## BATCH 3 — Data Models

1. Create `lib/models/meeting_time_model.dart`
   - Fields: `days` (List<String>), `startTime` (String), `endTime` (String)
   - `.toMap()` and `.fromMap()` methods
2. Create `lib/models/course_model.dart`
   - All fields as specified in Section 3.2
   - `.toMap()` and `.fromMap()` methods
   - `meetingTimes` serialized as List<Map>
3. Create `lib/models/schedule_model.dart`
   - All fields as specified in Section 3.3
   - `.toMap()` and `.fromMap()` methods

---

## BATCH 4 — Device ID Service

1. Create `lib/services/device_id_service.dart`
2. On first app launch: generate a UUID v4, store in SharedPreferences under key `device_id`
3. On subsequent launches: read from SharedPreferences
4. Expose `Future<String> getDeviceId()` as a static/singleton method
5. Write a simple test: call getDeviceId() twice, assert same value returned

---

## BATCH 5 — Firestore Service

1. Create `lib/services/firestore_service.dart`
2. Implement the following methods:

```
getSchedulesStream(deviceId)         → Stream<List<Schedule>>
createSchedule(deviceId, name)       → Future<void>
updateScheduleName(deviceId, scheduleId, name) → Future<void>
deleteSchedule(deviceId, scheduleId) → Future<void>
deleteMultipleSchedules(deviceId, ids) → Future<void>
pinSchedule(deviceId, scheduleId)    → Future<void>  // unpins all others first
unpinSchedule(deviceId, scheduleId)  → Future<void>
getPinnedSchedule(deviceId)          → Future<Schedule?>

getCoursesStream(deviceId, scheduleId)           → Stream<List<Course>>
addCourse(deviceId, scheduleId, course)          → Future<void>
updateCourse(deviceId, scheduleId, course)       → Future<void>
deleteCourse(deviceId, scheduleId, courseId)     → Future<void>
```

3. `pinSchedule` must first query all schedules with isPinned == true and set them to false in a batch write before setting the target to true
4. All writes use `updatedAt: FieldValue.serverTimestamp()`
   
---

---

# PHASE 2 — NAVIGATION SHELL
> Goal: App has correct bottom nav, screen routing, and placeholder screens.

---

## BATCH 6 — App Shell & Bottom Navigation

1. Create `lib/app.dart` with `MaterialApp`
   - Set theme: light, clean sans-serif font (default or Google Fonts)
   - Define named routes for Screen 1, Screen 2, Screen 3
2. Create `lib/widgets/main_shell.dart`
   - `BottomNavigationBar` with 2 tabs: Default (pin icon), Schedules (grid icon)
   - Uses `IndexedStack` to preserve state between tabs
3. Replace default `main.dart` counter content with `MainShell`
4. Create placeholder screens for Screen 1, Screen 2, Screen 3 (each shows only its title text)
5. Confirm navigation between tabs works on device

---

---

# PHASE 3 — SCREEN 2 (ALL SCHEDULES)
> Goal: Students can create, view, select, and delete schedules.

---

## BATCH 7 — Schedule Card Widget

1. Create `lib/screens/screen2_schedules/widgets/schedule_card.dart`
2. Card displays: schedule name, course count, pin indicator badge (if isPinned)
3. Top-right corner: 🗑️ delete `IconButton`
4. Card has a checkbox overlay (hidden by default, visible in multi-select mode)
5. Card accepts props: `schedule`, `isSelected`, `isMultiSelectMode`, `onTap`, `onLongPress`, `onDeleteTap`
6. Style: rounded corners, subtle shadow, comfortable padding

---

## BATCH 8 — All Schedules Screen (Screen 2)

1. Create `lib/screens/screen2_schedules/all_schedules_screen.dart`
2. StreamBuilder listening to `getSchedulesStream`
3. Renders schedule cards in a horizontal scroll (if many) or vertical list
4. State management:
   - `isMultiSelectMode` bool
   - `selectedIds` Set<String>
5. Long press → enter multi-select mode, select that card
6. Tap in multi-select → toggle selection
7. App bar in multi-select mode shows selected count and a delete button
8. Tap outside any card or press back → exit multi-select
9. Empty state: "No schedules yet. Tap + to create one."
10. Bottom-right FAB: circular, uses add icon

---

## BATCH 9 — Create Schedule + FAB Logic

1. FAB tap:
   - Calls `createSchedule(deviceId, "New Schedule")`
   - On success: navigates to Screen 3 for the new schedule, with `openEditorOnLoad: true` flag
2. Individual delete icon tap:
   - Shows `ConfirmDialog` with single-schedule message
   - On confirm: calls `deleteSchedule`, shows toast
3. Bulk delete button tap:
   - Shows `ConfirmDialog` with count in message
   - On confirm: calls `deleteMultipleSchedules`, exits multi-select mode, shows toast

---

## BATCH 10 — Confirm Dialog Widget

1. Create `lib/widgets/confirm_dialog.dart`
2. Accepts: `title` (String), `message` (String), `confirmLabel` (String), `onConfirm` callback
3. Two actions: Cancel (dismisses) and confirm button (calls onConfirm then dismisses)
4. Confirm button styled in red/destructive color
5. Reusable across all delete flows

---

---

# PHASE 4 — COURSE EDITOR
> Goal: Students can add and edit courses with all fields.

---

## BATCH 11 — Color Picker Widget

1. Create `lib/widgets/color_picker_row.dart`
2. Renders 9 color circles in a horizontal row
3. Selected circle shows a white checkmark overlay
4. Accepts: `selectedColorHex`, `onColorSelected` callback
5. Uses color constants from `app_colors.dart`

---

## BATCH 12 — Course Editor Bottom Sheet

1. Create `lib/widgets/course_editor_sheet.dart`
2. Accepts: `scheduleId`, `course` (null = add mode, non-null = edit mode), `onSave`, `onDelete`
3. Fields in order:
   - Course Title (TextFormField, required)
   - Color picker row (ColorPickerRow widget)
   - Class Mode dropdown (dropdown_button2)
   - Course Type dropdown (dropdown_button2, nullable, shows "None" as first option)
   - Meeting Times section (visible only when classMode != asynchronous):
     - Day checkboxes row (Mon Tue Wed Thu Fri Sat Sun)
     - Start Time picker (time picker dialog)
     - End Time picker (time picker dialog)
     - "Add Another Meeting Time" text button (adds a new row)
     - Each meeting time row has a remove icon
   - Instructor (TextFormField, optional)
   - Room No. (TextFormField, optional)
4. Bottom actions:
   - Save button (validates title non-empty)
   - Delete button (edit mode only, red/text style)
5. ClassMode onChange: if Asynchronous selected, hide entire Meeting Times section with animation

---

## BATCH 13 — Meeting Times Subsection

1. Inside Course Editor, meeting times managed as a local `List<MeetingTimeInput>`
2. Each row:
   - 7 day toggle chips (Mon–Sun)
   - Start time button → opens TimePickerDialog
   - End time button → opens TimePickerDialog
   - Remove row icon (only shown if more than one row)
3. "Add Another Meeting Time" appends a blank row to the list
4. On save: convert list to `List<MeetingTime>` models
5. Time display format: 12-hour (e.g. "8:00 AM") using `intl` package

---

---

# PHASE 5 — SCREEN 3 (SCHEDULE DETAIL)
> Goal: Students can view a schedule's timetable and manage courses and schedule settings.

---

## BATCH 14 — Timetable Grid Widget (Core)

1. Create `lib/screens/screen3_detail/widgets/timetable_grid.dart`
2. Outer widget: `SingleChildScrollView(scrollDirection: Axis.horizontal)` wrapping the grid
3. Grid structure:
   - Fixed left column: time labels (e.g. 7:00, 7:30, 8:00...) at 30-min intervals
   - 7 day columns (Mon–Sun), fixed minimum width per column
4. Time range: 7:00 AM to 9:00 PM (configurable constant)
5. Each 30-minute slot = fixed pixel height (e.g. 40px)
6. Grid lines: subtle horizontal lines per hour, vertical lines per day
7. Day header row pinned at top with day abbreviations
8. Accepts: `courses` (List<Course>), `onCourseTap` callback

---

## BATCH 15 — Course Blocks on Grid

1. Create `lib/screens/screen3_detail/widgets/time_block.dart`
2. For each course's meetingTimes:
   - For each day in days list:
     - Calculate top offset from startTime
     - Calculate height from duration
     - Render as `Positioned` block inside a `Stack`
3. Block displays: course title (white text, truncated), class mode badge (small label)
4. Block tappable → calls `onCourseTap(course)`
5. Conflict detection (in `time_utils.dart`):
   - If two courses overlap on the same day → render side by side at half column width
6. Asynchronous courses: render in a separate "Async / No Schedule" section below the grid as small chips

---

## BATCH 16 — Schedule Detail Screen (Screen 3)

1. Create `lib/screens/screen3_detail/schedule_detail_screen.dart`
2. Receives `scheduleId` and `openEditorOnLoad` bool as route arguments
3. Loads schedule doc + courses stream from Firestore
4. Top app bar — icons only:
   - 📌 Pin icon: calls `pinSchedule` or `unpinSchedule`, shows toast
   - ✏️ Edit icon: shows rename dialog (AlertDialog with TextField prefilled with current name) → calls `updateScheduleName` → toast
   - ➕ Add icon: opens `CourseEditorSheet` in add mode
   - 🗑️ Delete icon: shows ConfirmDialog → calls `deleteSchedule` → navigates back → toast
5. If `openEditorOnLoad == true`: open CourseEditorSheet after first frame (using `WidgetsBinding.instance.addPostFrameCallback`)
6. Course tap → opens CourseEditorSheet in edit mode prefilled with course data
7. Empty state: "Tap ➕ to add your first course"

---

## BATCH 17 — Course Editor Save & Delete Wiring

1. In CourseEditorSheet:
   - Save (add mode): calls `addCourse` → closes sheet → shows toast
   - Save (edit mode): calls `updateCourse` → closes sheet → shows toast
   - Delete (edit mode): shows ConfirmDialog → on confirm: calls `deleteCourse` → closes sheet → shows toast
2. Validate: if title is empty, show inline validation error, do not close sheet
3. Validate: if classMode is not asynchronous and no meeting times have any day selected, show inline warning (non-blocking, still allows save)

---

---

# PHASE 6 — SCREEN 1 (DEFAULT TIMETABLE)
> Goal: Pinned schedule is shown on the home tab automatically.

---

## BATCH 18 — Default Timetable Screen (Screen 1)

1. Create `lib/screens/screen1_default/default_timetable_screen.dart`
2. On load: calls `getPinnedSchedule(deviceId)`
3. If pinned schedule found:
   - Load its courses stream
   - Render TimetableGrid (same widget as Screen 3) in read-only mode (onCourseTap does nothing)
   - Show schedule name as screen title
4. If no pinned schedule:
   - Empty state: "No default schedule set. Go to Schedules and pin one."
   - Button: "Go to Schedules" → switches bottom nav to Tab 2
5. Screen 1 refreshes automatically when pinned schedule changes (reactive via Firestore stream)

---

---

# PHASE 7 — POLISH & EDGE CASES
> Goal: All toasts fire, all dialogues appear, all edge cases handled.

---

## BATCH 19 — Toast Integration Audit

1. Walk through every user action listed in Section 7
2. Confirm each has a `Fluttertoast.showToast(...)` call after its Firestore operation completes
3. Ensure toasts use constants from `app_strings.dart` (no hardcoded strings in UI)
4. Ensure toasts do not fire if the operation throws an error

---

## BATCH 20 — Edge Cases & Empty States

1. Schedule with zero courses: timetable grid renders empty with prompt text
2. Schedule name empty string edge: default to "Untitled Schedule" if rename is saved blank
3. All schedules deleted: Screen 2 shows empty state
4. Pinned schedule deleted: Screen 1 immediately shows empty state (stream update)
5. Two courses fully overlapping same day/time: both rendered side by side (confirm overlap logic from Batch 15 works)
6. Very long course title: truncated with ellipsis inside time block, full title shown in editor
7. Meeting time where endTime <= startTime: show inline validation error in editor, block save

---

## BATCH 21 — Final Integration Test

1. Run `flutter analyze` — fix all warnings and errors
2. Full flow test on physical Android 12 device:
   - Create 3 schedules
   - Add courses to each with all field combinations
   - Pin one, confirm Screen 1 shows it
   - Edit a course, confirm changes persist
   - Delete a course, confirm toast fires
   - Bulk delete 2 schedules, confirm toast shows count
   - Kill app and reopen — confirm all data persists (Firestore offline + online)
3. Fix any issues found during test

---

---

# PHASE 8 — OCR IMPORT (PHASE 2, AFTER PHASE 1 COMPLETE)
> Goal: Student uploads a schedule image; AI parses and plots it as a draft.

---

## BATCH 22 — OCR Screen Shell

1. Add Tab 3 to bottom nav: "Import" (camera/scan icon)
2. Create `lib/screens/screen4_ocr/ocr_import_screen.dart`
3. Screen shows:
   - Large upload area / button: "Upload Schedule Image"
   - Subtext: "Supports photos, screenshots, or scanned PDFs"
   - Empty state illustration

---

## BATCH 23 — Image Picker Integration

1. Add `image_picker` package to pubspec.yaml
2. On upload button tap: show action sheet — Camera / Gallery
3. Selected image previewed on screen before processing
4. "Process Image" button appears after image is selected

---

## BATCH 24 — Gemini Flash OCR Call

1. Add `http` or `google_generative_ai` package
2. On "Process Image" tap:
   - Convert image to base64
   - Send to Gemini Flash free-tier API (multimodal) with prompt:
     ```
     Extract all course schedule information from this image.
     Return a JSON array of courses. Each course must have:
     title, days (array of Mon/Tue/Wed/Thu/Fri/Sat/Sun), startTime (HH:mm 24h), endTime (HH:mm 24h),
     instructor (or null), roomNo (or null).
     Return only valid JSON. No explanation.
     ```
   - Show loading indicator during API call
3. Parse JSON response into a List<Course> draft
4. On parse failure: show error snackbar "Could not read schedule. Please try a clearer image."

---

## BATCH 25 — Draft Review & Confirm

1. After successful parse: navigate to a draft review screen
2. Draft review shows:
   - Parsed courses as an editable list (each row tappable → opens CourseEditor prefilled)
   - Student can remove courses from the draft before saving
   - "Save as New Schedule" button at bottom
3. On save:
   - Creates a new schedule named "Imported Schedule [date]"
   - Writes all confirmed courses to Firestore
   - Navigates to Screen 3 for the new schedule
   - Shows toast: "Schedule imported"
4. Student can also discard the entire draft and go back

---

---

*End of Iskeddy System Architecture v1.0*
*Phase 1–7: Core app | Phase 8: OCR Import (post-launch)*
