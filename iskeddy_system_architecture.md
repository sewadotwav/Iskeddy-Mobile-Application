# Iskeddy — Complete System Architecture & Agentic Build Plan

> **Stack:** Flutter 3.44+ · Dart 3.12+ · Firebase Firestore · Google Antigravity (Agent Mode)
> **Device:** Android 12 · Physical device via USB/wireless ADB
> **Scope:** Single-module · No auth · No login · No accounts · No AI chatbot · No friends

---

## 1. APP OVERVIEW

Iskeddy is a manual class schedule maker for students. Students create and manage
multiple schedules, add and edit course entries within each schedule, and view their
courses through a clean card-based list grouped by day. One schedule can be pinned as
the default, which is shown on the app's home tab filtered to the current day only.

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
│   │   ├── all_schedules_screen.dart           # Root tab — list + multi-select
│   │   └── widgets/
│   │       └── schedule_card.dart
│   └── screen3_detail/
│       └── schedule_detail_screen.dart         # Pushed screen — full schedule view
├── components/                       # Shared, reusable widget library — flat
│   ├── app_header.dart               # Logo-only centered header
│   ├── app_pill.dart                 # Generic pill/badge
│   ├── app_text_styles.dart          # Centralized text style helper (appFont)
│   ├── app_toast.dart                # Toast wrapper
│   ├── circular_icon_button.dart     # Small circular tap target
│   ├── color_picker_grid.dart        # 10-color fixed picker (2 rows of 5)
│   ├── confirm_dialog.dart           # Reusable confirmation dialogue
│   ├── course_card.dart              # Single course list item (shared)
│   ├── course_detail_sheet.dart      # Course info + notes bottom sheet
│   ├── course_editor_sheet.dart      # Shared add/edit course popup
│   ├── empty_state.dart              # Generic empty-state widget
│   ├── name_schedule_dialog.dart     # Schedule naming/rename dialog
│   ├── pill_button.dart              # Full-width pill action button
│   ├── schedule_card.dart            # Schedule list item
│   ├── absence_tracker_sheet.dart    # Sub-stats + course list for absence tracking
│   └── course_tracker_sheet.dart     # Per-course absence/late tracker
└── utils/
    ├── time_utils.dart               # Time parsing, gap/break + stats calculation
    ├── course_list_builder.dart      # GroupedCourseList + TodayCourseList widgets
    └── tracker_utils.dart            # Absence/late computation logic
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

Every course regardless of class mode uses meetingTimes to define when it happens.
Asynchronous courses are not exempt — students still block out day/time ranges.

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
  String? notes;                    // Optional short note per course
  List<MeetingTime> meetingTimes;
  int? maxAbsences;                 // null = tracker not yet set up
  int absenceCount;                 // raw logged absences, default 0
  int lateCount;                    // raw logged lates, default 0
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
                              ├── instructor, roomNo, notes
                              ├── maxAbsences (int | null)
                              ├── absenceCount (int, default 0)
                              ├── lateCount (int, default 0)
                              ├── createdAt, updatedAt
                              └── meetingTimes : Array<Map{days, startTime, endTime}>
```

Identity is a UUID generated on first app launch stored in SharedPreferences.

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
          && isOptionalString(data, 'notes');
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
| 1 | Lavender | #CDC5FA |
| 2 | Mint / Seafoam | #BDDBD9 |
| 3 | Sky Blue | #C4E6FF |
| 4 | Khaki / Olive Light | #E4E0B6 |
| 5 | Orchid Pink | #F9CFFF |
| 6 | Pale Yellow | #FDF6A8 |
| 7 | Peach | #FFE8C4 |
| 8 | Rosy Tan | #E4BEAB |
| 9 | Pink | #FDBDD2 |
| 10 | Light Green | #BEE89D |

### 6.2 Primary Accent Color

Ink Black #040505 — all primary buttons, active bottom-nav state, bold headers,
selected-state rings/borders, primary icons.

Background: White #FFFFFF everywhere.
Secondary text: Neutral mid-gray.

### 6.3 Class Mode Options

| Display Label | Firestore Value |
|---|---|
| Onsite | onsite |
| Synchronous | synchronous |
| Asynchronous | asynchronous |

### 6.4 Course Type Options (nullable)

Lecture / Lab / Seminar / Workshop

---

## 7. REUSABLE COMPONENT LIBRARY

All shared widgets live under lib/components/ (flat, no subfolders).

| Component | File | Used In |
|---|---|---|
| AppHeader | app_header.dart | Screen 1, Screen 2 |
| AppPill | app_pill.dart | Badges, status tags, day toggles |
| AppTextStyles (appFont) | app_text_styles.dart | Every screen and component |
| AppToast | app_toast.dart | Every toast trigger |
| CircularIconButton | circular_icon_button.dart | Pin, pencil, FAB, close, trash |
| ColorPickerGrid | color_picker_grid.dart | Course Editor |
| ConfirmDialog | confirm_dialog.dart | All delete actions |
| CourseCard | course_card.dart | Screen 1, Screen 3 |
| CourseDetailSheet | course_detail_sheet.dart | Tapping a course card |
| CourseEditorSheet | course_editor_sheet.dart | Screen 3 add/edit |
| EmptyState | empty_state.dart | All empty screens |
| NameScheduleDialog | name_schedule_dialog.dart | Create/rename schedule |
| PillButton | pill_button.dart | All primary action buttons |
| ScheduleCard | schedule_card.dart | Screen 2 |
| AbsenceTrackerSheet | absence_tracker_sheet.dart | Absence tracker entry |
| CourseTrackerSheet | course_tracker_sheet.dart | Per-course tracker |

---

## 8. NAVIGATION MODEL

Screen 1 and Screen 2 are root tabs (IndexedStack, bottom nav visible).
Screen 3 is pushed via Navigator.push (bottom nav hidden, back arrow shown).

Bottom nav — Screens 1 & 2 only:
  Left: document/list icon → All Schedules (Screen 2)
  Right: pin icon → Default Timetable (Screen 1)
Active: #040505 filled circle, white icon. Inactive: plain gray icon.

---

## 9. SCREEN 1 — DEFAULT TIMETABLE (root tab, read-only)

Shows the pinned schedule's courses for today's actual date only.

Layout:
1. AppHeader
2. Pinned schedule name, bold large
3. Flat list of CourseCard widgets for today's weekday, sorted by startTime
4. BreakDivider between consecutive courses where gap >= 30 minutes
5. Read-only — tapping a course card opens CourseDetailSheet (view + notes only)

Empty states:
  No pinned schedule: EmptyState with "Go to Schedules" button
  No classes today: EmptyState text only, no button

---

## 10. SCREEN 2 — ALL SCHEDULES (root tab)

Normal mode:
1. AppHeader
2. "Your Schedules" + AppPill "[N] SCHEDULES"
3. ScheduleCard list: name, course count pill, pin glyph, trash icon
4. Long press enters multi-select mode
5. FAB opens NameScheduleDialog

Multi-select mode:
  Header replaced with: back arrow / "[N] selected" / trash icon
  Checkboxes on cards, black border on selected
  Bottom nav stays visible
  System back exits multi-select

---

## 11. SCREEN 3 — SCHEDULE DETAIL (pushed screen, editable)

Layout:
1. Back arrow
2. Schedule name + pin icon + pencil icon
3. Subtitle: "Active Schedule · N Courses" or "N Courses"
4. Two stat cards (TOTAL HOURS / CLASS DAYS) — hidden if no courses
5. ABSENCE TRACKER widget — hidden if no courses (see Section 11.1)
6. Day filter tabs (M T W T F S S) — filters the course list below
7. Filtered course list grouped by selected day, sorted by startTime
8. BreakDivider for gaps >= 30 minutes
9. Tapping a course card opens CourseDetailSheet
10. FAB opens CourseEditorSheet (Add mode)

Empty state: EmptyState "No courses yet. Tap + to add your first course."
No delete-schedule action here — only available from Screen 2.

### 11.1 Absence Tracker Widget (inline on Screen 3)

A single full-width tappable card placed below the stat cards when courses exist.
Same visual style as the TOTAL HOURS / CLASS DAYS stat cards.

Displays:
  Label: "ABSENCE TRACKER"
  Sub-stat 1: "DROP RISK" / "N Courses" (amber color if N > 0)
  Sub-stat 2: "TOTAL ABSENCES" / "N"
  Right: chevron icon

Tapping opens AbsenceTrackerSheet.

---

## 12. NEW SCHEDULE CREATION FLOW

1. Tap FAB on Screen 2
2. NameScheduleDialog appears (cannot be empty)
3. On Create: createSchedule() → navigate to empty Screen 3
4. Student manually taps FAB on Screen 3 to add courses

---

## 13. ABSENCE & LATE TRACKER

### Rules
- Each course has its own independent tracker
- Student sets maxAbsences per course (professor's allowed limit)
- 3 lates = 1 effective absence (fixed global rule, not configurable per course)
- effectiveAbsences = absenceCount + floor(lateCount / 3)
- remaining = maxAbsences - effectiveAbsences
- Status thresholds:
    SAFE: remaining > 3
    AT RISK: remaining <= 3 and remaining > 0
    DROPPED: effectiveAbsences >= maxAbsences
    NOT SET UP: maxAbsences is null

### tracker_utils.dart

Pure Dart file, no Flutter imports. Exposes:
  enum TrackerStatus { notSetUp, safe, atRisk, dropped }
  class TrackerState { effectiveAbsences, remaining, latesConverted, status }
  TrackerState computeTrackerState(Course course)
  int dropRiskCount(List<Course> courses)
  int totalEffectiveAbsences(List<Course> courses)

### AbsenceTrackerSheet

Bottom sheet opened by tapping the Absence Tracker widget on Screen 3.
Uses getCoursesStream() for live updates.

Layout:
  Header: "Absence Tracker" + close button
  Two sub-stat cards: DROP RISK / TOTAL ABSENCES
  Scrollable list of course cards in their own colors with status pills
  Tapping a course card closes this sheet and opens CourseTrackerSheet

### CourseTrackerSheet

Per-course bottom sheet. Has four states:

NOT SET UP:
  Number selector for maxAbsences (min 1)
  Late rule info box
  "Set Up Tracker" primary button

SAFE / AT RISK / DROPPED (all share same layout):
  Two stat cards: ABSENCES (N/max) / LATES (N)
  Full-width status pill
  Warning banner (AT RISK and DROPPED only)
  LOG ABSENCE row: count display + minus/plus circular buttons
  LOG LATE row: count display + minus/plus circular buttons
  Info box: late conversion explanation
  "Done" primary button — writes all three tracker fields to Firestore via
    updateCourseTracker() then shows "Tracker updated" toast

Minus buttons disabled (opacity 0.3) when count is 0.
Plus ABSENCE button disabled when status is DROPPED.

### CourseDetailSheet (absence section)

An ABSENCE STATUS section is rendered between MEETING TIMES and NOTES:
  If maxAbsences is null: "Absence tracker not set up yet." info box
  Otherwise: bordered stat card showing effectiveAbsences/maxAbsences + status pill
    + breakdown info row (raw absences + lates breakdown)
  This section is fully read-only.

### Firestore Service additions

  Future<void> updateCourseTracker(
    String deviceId, String scheduleId, String courseId,
    { int? maxAbsences, int? absenceCount, int? lateCount }
  )
  Uses .update() with only the provided fields — no full course rewrite.

  Future<void> updateCourseNotes(
    String deviceId, String scheduleId, String courseId, String notes
  )
  Uses .update() on notes and updatedAt only.

---

## 14. COURSE DETAIL SHEET

Opened by tapping anywhere on a CourseCard (excluding the pencil icon).

Layout:
  Drag handle
  Header: colored circle swatch + course title + close button
  Class mode + course type AppPills
  Hrs/wk row (clock icon + computed hours per week for this course)
  MEETING TIMES section: one colored card per MeetingTime showing day, time range,
    instructor, room, class mode pill
  ABSENCE STATUS section (read-only, see Section 13)
  NOTES section: multiline text field + "Save Note" PillButton

---

## 15. COURSE EDITOR

Opened only from Screen 3 (FAB for add, pencil icon for edit).

Fields in order:
  Course Title (required)
  Course Color (ColorPickerGrid, 2 rows of 5, default first color)
  Class Mode dropdown / Course Type dropdown (side by side)
  Days (7 circular single-letter M T W T F S S toggles — always visible)
  Start Time / End Time (pill fields, side by side — always visible)
  Add another meeting time (text link)
  Instructor / Room No. (side by side, optional)

Actions:
  "Save Course" — validates title non-empty and endTime > startTime per row
  "Delete" — Edit mode only, opens ConfirmDialog

---

## 16. COURSE LIST & GROUPING LOGIC (time_utils.dart + course_list_builder.dart)

No calendar grid anywhere. All display uses vertical card lists.

time_utils.dart functions:
  timeToMinutes(String time) → int
  formatTime(String time) → String (12h display)
  formatTimeRange(String start, String end) → String
  hasBreakBefore(MeetingTime a, MeetingTime b) → bool (>= 30 min gap)
  totalWeeklyMinutes(List<Course> courses) → int
  distinctClassDays(List<Course> courses) → int
  formatTotalHours(List<Course> courses) → String ("X hrs / wk")
  formatClassDays(List<Course> courses) → String ("X Days")
  coursesForDay(List<Course> courses, String day) → List<_DayCourseEntry>
  activeDays(List<Course> courses) → List<String> (Mon→Sun order)
  weekdayString(int dartWeekday) → String

course_list_builder.dart widgets:
  GroupedCourseList({ required courses, scheduleId, deviceId })
    — used on Screen 3, groups by active days with headers
  TodayCourseList({ required courses, scheduleId, deviceId })
    — used on Screen 1, filters to today only, read-only (onEditTap no-op)

BreakDivider is a private widget inside course_list_builder.dart.

---

## 17. TOASTS & CONFIRMATIONS

Toasts:
  Schedule created / renamed / pinned / unpinned
  Course added / saved / deleted
  Schedule deleted / N schedules deleted
  Tracker updated
  Note saved

Confirmation dialogues:
  Delete single schedule / bulk delete / delete course
  All use ConfirmDialog with Cancel (gray) + Delete (black) PillButtons

---

## 18. PACKAGES (pubspec.yaml)

  firebase_core
  cloud_firestore
  shared_preferences
  uuid
  intl
  fluttertoast
  dropdown_button2

---

## 19. AGENTS.md (project root)

  # Iskeddy — Agent Rules
  
  Flutter 3.44 + Dart 3.12 + Firebase Firestore. No auth. No login.
  Target: Android 12 physical device.
  
  Folder: lib/components/ (flat) for all shared widgets.
  All Firestore ops through firestore_service.dart only.
  No business logic in UI widgets.
  Models are plain Dart with .toMap() and .fromMap().
  
  Rules:
  - No swipe-to-delete, always explicit button
  - All deletes require ConfirmDialog first
  - All major actions show AppToast after completion
  - isPinned: true on only one schedule at a time
  - Course mode never hides Days/Start/End fields
  - Course cards use colorHex as solid fill
  - Bottom nav visible on Screen 2 multi-select, hidden on Screen 3
  - New schedules always created through NameScheduleDialog
  - Absence tracker: 3 lates = 1 effective absence (fixed, not configurable)
  - updateCourseTracker() for tracker fields only, never full updateCourse()
  - updateCourseNotes() for notes field only

---

## 20. BUILD PLAN

### Phase 1 — Foundation (Complete)
  Batch 1: Project init, Firebase, pub get, flutterfire configure, offline persistence
  Batch 2: Constants & enums
  Batch 3: Data models (MeetingTime, Course, Schedule)
  Batch 4: Device ID service + test
  Batch 5: Firestore service (all CRUD methods)

### Phase 2 — Navigation Shell (Complete)
  Batch 6: app.dart, MainShell, bottom nav, placeholder screens

### Phase 3 — Shared Components (Complete)
  Batch 7: AppHeader, AppPill, AppTextStyles, CircularIconButton, ConfirmDialog,
    AppToast, PillButton
  Batch 8: ColorPickerGrid, EmptyState

### Phase 4 — Screen 2: All Schedules (Complete)
  Batch 9: ScheduleCard widget
  Batch 10: AllSchedulesScreen (StreamBuilder, multi-select state)
  Batch 11: NameScheduleDialog + FAB wiring
  Batch 12: Individual delete + bulk delete wiring

### Phase 5 — Course Editor (Complete)
  Batch 13: CourseEditorSheet (all fields)
  Batch 14: Multi-row meeting times (add/remove)

### Phase 6 — Course List & Grouping Logic (Complete)
  Batch 15: time_utils.dart
  Batch 16: CourseCard widget
  Batch 17: GroupedCourseList (Screen 3)
  Batch 18: TodayCourseList (Screen 1)

### Phase 7 — Screen 3: Schedule Detail (Complete)
  Batch 19: Screen shell (stat cards, grouped list, FAB, empty state)
  Batch 20: Pin/rename wiring
  Batch 21: CourseEditorSheet wiring (add + edit)

### Phase 8 — Screen 1: Default Timetable (Complete)
  Batch 22: Screen shell (pinned schedule, today filter, empty states)

### Phase 9 — Polish & Edge Cases (Complete)
  Batch 23: Toast integration audit
  Batch 24: Edge cases (empty rename, pinned schedule deleted, long titles,
    time validation, multi-select exit)
  Batch 25: Final integration test (full flow + offline persistence)

### Phase 9.5 — Post-Launch Feature Additions (Complete)
  Course Detail Sheet:
    CourseDetailSheet with meeting times, notes field, Save Note
    updateCourseNotes() Firestore method
    notes field added to Course model
    CourseCard gains onCardTap (opens detail) + retains onEditTap (opens editor)

  Absence & Late Tracker:
    tracker_utils.dart (pure Dart logic, TrackerStatus, TrackerState)
    Course model extended: maxAbsences, absenceCount, lateCount
    updateCourseTracker() Firestore method
    AbsenceTrackerSheet (sub-stats + course list in one sheet)
    CourseTrackerSheet (per-course: setup / safe / atRisk / dropped states)
    AbsenceTrackerWidget (private widget on Schedule Detail screen)
    CourseDetailSheet updated with read-only ABSENCE STATUS section

### Phase 10 — OCR Import (Active)
  Batch 26: OCR screen shell + bottom nav third tab
  Batch 27: Image picker (camera/gallery), preview, process button
  Batch 28: Gemini Flash multimodal API call, JSON parsing into draft courses
  Batch 29: Draft review screen — editable course list, manual corrections,
    confirm and save as new schedule, toast

---

## 21. PHASE 10 — OCR IMPORT DETAIL

### Overview

Students can upload a photo or screenshot of a printed or digital class schedule.
The image is sent to Gemini Flash (free tier multimodal API) which extracts course
data and returns it as structured JSON. The student reviews and edits the parsed
results before saving as a new schedule. Nothing is saved automatically.

### Navigation

A third tab is added to the bottom navigation bar:
  Left: document/list icon → All Schedules (Screen 2)
  Center: camera/scan icon → OCR Import (Screen 4, new)
  Right: pin icon → Default Timetable (Screen 1)

Screen 4 is a root tab, not a pushed screen. Bottom nav remains visible.

### Screen 4 — OCR Import

Layout (empty/initial state):
  AppHeader
  Large centered upload area: camera icon, "Upload Schedule Image" primary text,
    "Supports photos, screenshots, or scanned PDFs" secondary text
  Two PillButtons stacked:
    "Take Photo" (primary: black fill)
    "Choose from Gallery" (secondary: light gray fill)

After image selected:
  Image preview (constrained height, rounded corners, full width)
  "Process Image" PillButton (primary: black fill)
  "Choose Different Image" text link below

While processing (Gemini API call in progress):
  CircularProgressIndicator centered
  "Reading your schedule..." subtext

On parse error:
  AppToast: "Could not read schedule. Try a clearer image."
  Returns to the upload state

On parse success:
  Navigates to Draft Review Screen (pushed, bottom nav hidden)

### Gemini Flash API Call

Uses the existing flutter http package (already available transitively) or adds
the google_generative_ai package (the only new package for this phase).

Required package addition to pubspec.yaml:
  google_generative_ai: latest

Image is converted to base64 and sent as a multimodal message with this prompt:

  "Extract all course/subject schedule information from this image.
  Return ONLY a JSON array. No explanation, no markdown, no extra text.
  Each object must have these exact keys:
    title (string, required),
    days (array of strings using: Mon Tue Wed Thu Fri Sat Sun),
    startTime (string, 24h HH:mm format),
    endTime (string, 24h HH:mm format),
    instructor (string or null),
    roomNo (string or null),
    courseType (one of: Lecture Lab Seminar Workshop, or null)
  If a course meets at multiple different times, include it as
  multiple separate objects with the same title."

Gemini model: gemini-1.5-flash (free tier).
API key stored in a .env file and loaded via --dart-define-from-file=.env.
Never hardcoded. Never committed to git.

Response parsing:
  Strip any markdown code fences if present before JSON.parse.
  Map each parsed object to a DraftCourse (local model, not stored to Firestore).
  On any parse failure: show AppToast error, return to upload state.

### DraftCourse (local model, no Firestore)

```dart
class DraftCourse {
  String title;
  String colorHex;           // auto-assigned from courseColors in round-robin order
  List<MeetingTime> meetingTimes;
  String? instructor;
  String? roomNo;
  String? courseType;
  bool isIncluded;           // student can exclude a parsed course before saving
}
```

This model exists only during the draft review session. It is never written to
Firestore until the student confirms.

### Draft Review Screen (pushed from Screen 4)

Layout:
  Back arrow (returns to Screen 4, discards draft entirely)
  "Review Schedule" bold header
  Subtext: "N courses detected. Edit or remove any before saving."
  Scrollable list of DraftCourseCard widgets (one per parsed course)
  Bottom: NameScheduleDialog trigger + "Save as New Schedule" PillButton

DraftCourseCard widget (new, local to this screen):
  Course color fill (auto-assigned, tappable to change via ColorPickerGrid)
  Course title (editable inline TextFormField)
  Days chips (tappable to toggle, same circular M T W T F S S style)
  Start/End time (tappable pill fields, open native time picker)
  Instructor / Room No. (editable inline fields, optional)
  Course Type (dropdown, nullable)
  Toggle to exclude/include (right side: checkbox or eye icon)
    Excluded cards render with reduced opacity (0.4) and a strikethrough on title

On "Save as New Schedule":
  1. Open NameScheduleDialog (same component, reused)
  2. On name confirmed: createSchedule(deviceId, name)
  3. For each DraftCourse where isIncluded == true:
       Build a full Course object (new UUID, current DateTime, colorHex, all fields)
       Call addCourse(deviceId, newScheduleId, course)
  4. AppToast: "Schedule imported"
  5. Navigate to Screen 3 (the new schedule's detail view) and clear Screen 4's state

On back arrow from Draft Review:
  ConfirmDialog: "Discard this draft? The detected courses will not be saved."
  On confirm: pop back to Screen 4, reset to upload state

### Batch Detail

Batch 26 — OCR screen shell:
  Add third tab to MainShell bottom nav (camera icon, center position)
  Create lib/screens/screen4_ocr/ocr_import_screen.dart
  Build upload state UI: image area, Take Photo / Choose from Gallery buttons
  Wire image_picker: camera and gallery sources

Batch 27 — Image picker + preview:
  After image selected: show preview + Process Image button
  Add google_generative_ai to pubspec.yaml
  Add GEMINI_API_KEY to .env file (documented, not committed)
  Implement base64 image conversion

Batch 28 — Gemini API call + JSON parsing:
  Implement _processImage() async method
  Build API call with the exact prompt from Section 21
  Parse response into List<DraftCourse>
  Handle errors with AppToast + return to upload state
  Auto-assign colors to DraftCourses in round-robin from courseColors list

Batch 29 — Draft review screen:
  Create lib/screens/screen4_ocr/draft_review_screen.dart
  Build DraftCourseCard widget (editable inline fields, day toggles, exclude toggle)
  Wire NameScheduleDialog + save flow
  Wire back arrow ConfirmDialog
  Final integration test: photo → parse → review → edit → save → verify in Firestore

### What Not to Add in Phase 10
  No automatic saving without student confirmation
  No persistent draft storage (draft exists only in memory during the session)
  No batch re-processing after a failed parse (student re-uploads manually)
  No multi-image support (one image per import session)

---

*End of Iskeddy System Architecture.*