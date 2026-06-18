# Iskeddy - Manual Class Schedule Maker (Personal Learning Project)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.12%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Android-12%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License">
</p>

A single-module, agent-built class schedule maker for students, designed with Flutter and backed by Firebase Firestore. Students create multiple schedules, add and edit course entries inside each one, and view their classes through a clean card-based list grouped by day — with one schedule pinnable as the default, shown on the home tab filtered to today only. 

*Note: This project embraces an intuitive, agent-driven development workflow, where the codebase is iteratively crafted through continuous agent collaboration rather than strictly traditional manual authoring.*

---

## Table of Contents

- [Features](#features)
- [Demo](#demo)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Basic Setup](#1-basic-setup)
  - [Firebase Configuration](#2-firebase-configuration)
- [Usage](#usage)
- [Data Models & Firestore Schema](#data-models--firestore-schema)
- [Project Structure](#project-structure)
- [Technologies Used](#technologies-used)
- [Recent Updates](#recent-updates)
- [Testing](#testing)
- [License](#license)
- [Contact](#contact)
- [Troubleshooting](#troubleshooting)

---

## Features

### Mobile App
- **Multiple Schedules** - Create, name, and manage as many independent schedules as needed.
- **Pinned Default Schedule** - Pin one schedule as the default; the home tab shows only that schedule's classes, filtered to today's actual date.
- **Card-Based Course List** - No calendar grid anywhere — courses render as sorted, vertical `CourseCard` widgets grouped under weekday headers.
- **Shared Course Editor** - One bottom sheet handles both Add and Edit modes, with title, 10-swatch color picker, class mode, course type, multiple meeting times, instructor, and room number.
- **Multi-Select Bulk Delete** - Long-press any schedule card to enter multi-select mode and bulk-delete with a single confirmation.
- **Break Detection** - Automatically inserts a `BreakDivider` between consecutive courses whenever the gap is 30 minutes or more.
- **Weekly Stats** - Per-schedule "Total Hours / wk" and "Class Days" calculated live from meeting times.
- **No Login Required** - Identity is a UUID generated on first launch and stored locally — no accounts, no auth screens.
- **Real-time Synchronization** - Instant updates for schedules and courses via Firestore streams, with offline persistence.
- **Toast & Confirmation Feedback** - Every create, rename, pin, and delete action surfaces a toast; every delete requires an explicit confirmation dialog.

### Backend & Infrastructure
- **Firebase Firestore Backend** - Nested `devices/{deviceId}/schedules/{scheduleId}/courses/{courseId}` structure, no relational backend needed.
- **Device-Scoped Identity** - `device_id_service.dart` generates and persists a UUID via SharedPreferences on first launch; this UUID is the Firestore document ID.
- **Centralized Data Layer** - All Firestore reads/writes route through a single `firestore_service.dart`, with no business logic embedded in UI widgets.
- **Offline-First** - Firestore offline persistence enabled at project init so the app remains usable without connectivity.

### Security Features
- **Schema-Validated Writes** - Firestore Security Rules enforce field types, required strings, and valid enum values (`classMode`, `colorHex` format) before any document is accepted.
- **Immutable Device Records** - `devices/{deviceId}` documents allow create and read only — update and delete are always denied at the rules level.
- **Default-Deny Fallback** - A catch-all rule blocks read/write on any path not explicitly matched above.
- **No Personal Data Collected** - With no accounts and no auth, the only identifier stored is a locally generated UUID.

---

## Demo

**Public App**: Run locally on a physical Android 12 device via USB or wireless ADB

> **Note**: This is a development project built and tested against a single physical Android device rather than emulators or app stores.

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** >= 3.44
- **Dart** >= 3.12 (bundled with the Flutter SDK)
- **Android Studio** or **VS Code** with the Flutter and Dart plugins
- **A Firebase Project** with Firestore enabled
- **An Android 12 physical device** with USB debugging (or wireless ADB) enabled
- **Google AI Studio Account** (only required later, for the planned Gemini-powered OCR import phase)

---

## Installation

### 1. Basic Setup

#### Clone the Repository
```bash
git clone https://github.com/yourusername/iskeddy.git
cd iskeddy
```

#### Install Dependencies
```bash
flutter pub get
```

### 2. Firebase Configuration

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Firestore Database** in Native mode.
3. Run `flutterfire configure` from the project root and select your Firebase project to generate `firebase_options.dart`.
4. Deploy the Firestore Security Rules defined in the architecture doc (Section 5) to enforce `isValidSchedule` and `isValidCourse` validation on every write.
5. No collections need to be created manually — `devices`, `schedules`, and `courses` are created automatically on first write.

---

## Usage

### Connecting Your Device

Connect an Android 12 device over USB (or pair it via wireless ADB), then confirm it's detected:
```bash
flutter devices
```

### Running the App

```bash
flutter run
```

Useful flags during development:
```bash
flutter run --hot                 # Hot reload enabled (default)
flutter run -d <deviceId>         # Target a specific connected device
flutter clean && flutter pub get  # Reset build cache if dependencies misbehave
```

---

## Data Models & Firestore Schema

```text
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

- **`MeetingTime`** - `days` (list of weekday abbreviations), `startTime`, `endTime` (24h `HH:mm`). Used by every course regardless of class mode, including asynchronous ones.
- **`Course`** - title, one of 10 fixed `colorHex` values, `classMode` (`onsite` | `synchronous` | `asynchronous`), optional `courseType`, optional instructor/room, and a list of `meetingTimes`.
- **`Schedule`** - name, `isPinned` flag (only one schedule may be pinned at a time), timestamps.

---

## Project Structure

```text
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
├── components/                       # Shared, reusable widget library
│   ├── app_header.dart               # Calendar icon + "iskeddy" wordmark header
│   ├── app_pill.dart                 # Generic pill/badge (counts, status, tags)
│   ├── app_text_styles.dart          # Centralized text style definitions
│   ├── app_toast.dart                # Toast wrapper around fluttertoast
│   ├── circular_icon_button.dart     # Reusable small circular icon button
│   ├── color_picker_grid.dart        # 10-color fixed picker (2 rows of 5)
│   ├── confirm_dialog.dart           # Reusable confirmation dialogue
│   ├── course_card.dart              # Single course list item (shared)
│   ├── empty_state.dart              # Generic empty-state widget (icon, title, subtitle, optional button)
│   ├── pill_button.dart              # Pill-shaped action button (Save/Create/Cancel)
│   └── schedule_card.dart            # Schedule list item — normal + multi-select modes
│   ├── course_editor_sheet.dart
│   ├── name_schedule_dialog.dart
└── utils/
    └── time_utils.dart               # Time parsing, gap/break + stats calculation
```
---

## Technologies Used

### Frontend & Core
- **Flutter (3.44+)** - Cross-widget UI toolkit, single Android target for this phase
- **Dart (3.12+)** - Application language
- **Material `MaterialApp`** - Navigation shell with `IndexedStack` for the two root tabs

### Backend & Services
- **Firebase Firestore** - Nested NoSQL document store for devices, schedules, and courses
- **`firebase_core`** - Firebase app initialization

### Local Persistence & Utilities
- **`shared_preferences`** - Stores the device-generated UUID on first launch
- **`uuid`** - Generates the device identifier
- **`intl`** - Date/time formatting for course times and weekday grouping
- **`fluttertoast`** - Underlying toast mechanism wrapped by `AppToast`
- **`dropdown_button2`** - Class Mode and Course Type dropdowns in the Course Editor

### Development Tools
- **Google Antigravity** - Agent-driven build workflow across all 10 phases
- **Android Studio / VS Code** - IDE with Flutter & Dart tooling
- **ADB (USB / Wireless)** - Physical Android 12 device deployment and debugging

---

## Recent Updates

- **Foundation Complete**: Project init, Firebase wiring, `flutterfire configure`, offline persistence, constants/enums, data models, device ID service, and the full Firestore service layer.
- **Shared Component Library Consolidated**: `app_header`, `app_pill`, `app_text_styles`, `app_toast`, `circular_icon_button`, `color_picker_grid`, `confirm_dialog`, `course_card`, `empty_state`, `pill_button`, and `schedule_card` all centralized under `lib/components/` so every screen pulls from one shared library instead of per-screen widget folders.
- **Navigation Shell**: Bottom nav with `IndexedStack` wrapping Screen 1 and Screen 2, with Screen 3 registered as a pushed route with the bottom nav hidden.
- **Agent-Assisted Workflow**: Entire build broken into 29 sequential batches across 10 phases, driven through Google Antigravity Agent Mode rather than manual file-by-file authoring.
- **Upcoming - OCR Import (Phase 10)**: Planned post-launch phase adding a third bottom-nav tab, image picker (camera/gallery), a Gemini 2.5 Flash multimodal call to parse an uploaded schedule image into draft courses, and a review screen before saving.

---

## Testing

```bash
# Run static analysis
flutter analyze

# Run unit/widget tests (if configured)
flutter test
```

Final validation is a manual integration pass on a physical Android 12 device covering the full create → add courses → pin → edit → delete flow, with Firestore tested both online and in offline mode.

---

## License

This project is licensed under the **MIT License** - see the LICENSE file for details.

---

## Contact

### Project Links
- **Repository**: [https://github.com/sewadotwav/Iskeddy-Mobile-Application.git]

### Get In Touch
- **Author**: Dimalanta, Miles C.

---

## Troubleshooting

### Common Issues

#### Issue: "flutterfire configure fails or hangs"
**Solution:**
Confirm you're logged into the Firebase CLI (`firebase login`) and that the FlutterFire CLI is activated:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

#### Issue: "Firestore permission denied on write"
**Solution:**
Check that the document being written matches the shape expected by `isValidSchedule` or `isValidCourse` in the Security Rules — missing fields, wrong types, or an invalid `classMode`/`colorHex` value will be rejected before reaching the database.

#### Issue: "Device not detected by `flutter devices`"
**Solution:**
Re-enable USB debugging in Developer Options, accept the RSA fingerprint prompt on the device, or re-pair via `adb pair` for wireless ADB. Run `adb devices` to confirm the device is authorized.

#### Issue: "Pinned schedule isn't showing on the home tab"
**Solution:**
Only one schedule can have `isPinned == true` at a time. Confirm the pin toggle on Screen 3 actually unpinned the previous schedule before pinning the new one — check the toast confirmation after tapping the pin icon.

---

<p align="center">© 2026 Iskeddy. All rights reserved.</p>
