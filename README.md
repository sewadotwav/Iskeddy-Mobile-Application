# Iskeddy - Class Schedule Maker (Personal Learning Project)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Platform-Android_12+-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white" alt="Gemini">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License">
</p>

A class schedule maker and academic tracker designed for students, built with modern Flutter and Firebase technologies. The application allows students to create and manage multiple schedules, add and edit course entries, view their courses through an intuitive card-based list grouped by day, and track absences and lates per course — all without the clutter of a traditional calendar grid.

*Note: This project embraces an intuitive, agent-driven development workflow, where the codebase is iteratively crafted through continuous AI collaboration rather than strictly traditional manual authoring.*

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Basic Setup](#1-basic-setup)
  - [Service Configuration](#2-service-configuration)
- [Usage](#usage)
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
- **Multiple Schedules** - Create and manage different schedules for semesters or terms.
- **Default Timetable** - Pin a specific schedule to view today's active classes instantly on the home tab.
- **Course Management** - Add detailed course entries including title, color, meeting times, room numbers, and instructors.
- **Visual Organization** - Choose from a curated 10-color fixed palette to visually organize classes.
- **Flexible Class Modes** - Support for Onsite, Synchronous, and Asynchronous learning blocks, assignable per meeting time slot.
- **Course Types** - Tag each meeting slot as Lecture, Lab, Seminar, or Workshop.
- **Frictionless Experience** - No login, no accounts, and no authentication required. Identity is managed transparently via device UUID.
- **Clean Interface** - A card-based list approach grouped by day, bypassing the visual constraints of a calendar grid.
- **Day Filter** - Day-of-week filter tabs (M T W T F S S) on the Schedule Detail screen to quickly zero in on a specific day's load.
- **Schedule Statistics** - Automatic stat cards per schedule showing total weekly hours and number of distinct class days.
- **Offline Persistence** - Firestore offline capabilities to view and manage schedules without an internet connection.
- **Absence & Late Tracker** - Built-in per-course absence and late logging. Set a maximum absence allowance per course, log incidents, and monitor drop risk status (Safe, At Risk, Dropped). The global rule of 3 lates equaling 1 effective absence is enforced automatically.
- **Course Detail Sheet** - Tap any course card to view a full detail sheet with meeting times, instructor/room info, real-time absence status, and a notes field.
- **Course Notes** - Add and save custom multi-line notes to any individual course for quick reference.
- **AI-Powered OCR Import** - Integrated Gemini Vision API to automatically parse detailed class schedules from multiple uploaded images or camera photos, with a full editable draft review flow before saving.

### Backend & Infrastructure
- **Firebase Firestore** - Robust NoSQL database for syncing user data transparently.
- **Device-Based Identity** - UUID generation coupled with SharedPreferences for seamless user sessions.

### Security Features
- **Database Rules** - Strict Firestore security rules ensuring data is only manipulated according to defined schemas.
- **Validation** - Enforced schema validation directly at the database level for robust data integrity.

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (version 3.44 or higher)
- **Dart SDK** (version 3.12 or higher)
- **Android Studio** or **VS Code** with Flutter extensions
- **A Firebase Project**
- **A Google Gemini API Key** - Required for the OCR Import feature. Obtain one from [Google AI Studio](https://aistudio.google.com/).
- **Android Device or Emulator** (Targeting Android 12+)

---

## Installation

### 1. Basic Setup

#### Clone the Repository
```bash
git clone https://github.com/sewadotwav/Iskeddy.git
cd Iskeddy
```

#### Install Dependencies
```bash
flutter pub get
```

### 2. Service Configuration

#### Firebase Setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable Firestore Database.
3. Configure Firestore security rules using the provided `firestore.rules`.
4. Run `flutterfire configure` to generate the `firebase_options.dart` configuration file for your specific Firebase project.

#### Gemini API Key Setup
1. Get a free API key from [Google AI Studio](https://aistudio.google.com/).
2. Create the file `lib/config/secrets.dart` in the project (this file is git-ignored for security).
3. Add the following line inside:
```dart
const String geminiApiKey = 'YOUR_API_KEY_HERE';
```

---

## Usage

### Starting the Development Server

```bash
# Run the application on a connected device or emulator
flutter run
```

---

## Project Structure

```text
Iskeddy/
├── lib/
│   ├── constants/     # Enums, colors, and string constants
│   ├── models/        # Data models (Course, Schedule, MeetingTime, DraftCourse)
│   ├── screens/
│   │   ├── screen1_default/   # Default Timetable tab (today's classes)
│   │   ├── screen2_schedules/ # All Schedules tab (list + multi-select)
│   │   ├── screen3_detail/    # Schedule Detail screen (full editable view)
│   │   └── screen4_ocr/       # OCR Import tab + Draft Review screen
│   ├── services/      # Device ID and Firestore services
│   ├── utils/         # Time parsing, course grouping, and tracker logic
│   ├── components/    # Shared reusable UI components (flat folder)
│   ├── config/        # secrets.dart (git-ignored; stores Gemini API key)
│   ├── app.dart       # MaterialApp and routing
│   └── main.dart      # Application entry point
├── android/           # Android-specific build configurations
├── assets/            # Fonts and static assets
├── firestore.rules    # Firestore security rules
├── pubspec.yaml       # Project dependencies
└── README.md          # Project documentation
```

---

## Technologies Used

### Frontend & Core
- **Flutter (3.44+)** - UI toolkit for building natively compiled applications
- **Dart (3.12+)** - Programming language optimized for UI
- **IndexedStack** - For persistent bottom navigation state

### Backend & Services
- **Firebase Core** - Core Firebase services initialization
- **Cloud Firestore** - Real-time NoSQL database with offline persistence
- **SharedPreferences** - Local storage for device UUID and simple state

### Third-Party Packages
- **uuid** - Unique device identifier generation
- **intl** - Internationalization and date formatting
- **fluttertoast** - Toast notifications for user actions
- **dropdown_button2** - Enhanced dropdown components
- **google_generative_ai** - Integration with Google's Gemini Vision models for robust OCR
- **image_picker** - Device camera and gallery access for uploading schedule images

---

## Recent Updates

- **Navigation Shell**: Implemented robust 3-tab navigation using an `IndexedStack` to persist state across Default Timetable, All Schedules, and OCR Import tabs.
- **Shared Components**: Built a comprehensive reusable component library including dialogs, pills, circular buttons, tracker sheets, and dynamic cards to maintain visual consistency.
- **Data Architecture**: Finalized Firestore schema and strict security rules to enforce data integrity without requiring traditional user accounts.
- **Course Editor**: Developed an intuitive bottom sheet interface capable of handling both course creation and modification with dynamic multi-slot time block management.
- **Course Detail Sheet**: Added a tappable detail view per course showing meeting times, class mode and type pills, weekly hours, absence status, and an editable notes field.
- **Absence & Late Tracker (Phase 9.5)**: Implemented a full per-course tracking system with configurable maximum absences, late logging (3 lates = 1 absence), and drop risk status indicators (Safe, At Risk, Dropped) surfaced in both the Schedule Detail screen and a dedicated tracker bottom sheet.
- **Schedule Statistics**: Auto-computed stat cards on each Schedule Detail screen displaying total weekly hours and distinct class day count.
- **AI-Powered OCR Import (Phase 10)**: Integrated Gemini Vision API (using `gemini-3.6-flash`) to allow users to upload multiple images or camera photos and automatically parse their class schedule into draft courses.
- **Advanced Draft Review**: Re-architected the draft course review card for a clean, hierarchical layout. Users can assign Class Modes and Course Types granularly per meeting slot, edit titles, change colors, add/remove time slots, and include/exclude individual courses before saving.

---

## Testing

```bash
# Run automated tests
flutter test
```

---

## License

This project is licensed under the **MIT License** - see the LICENSE file for details.

---

## Contact

### Project Links
- **Repository**: [https://github.com/sewadotwav/Iskeddy](https://github.com/sewadotwav/Iskeddy)

### Get In Touch
- **Author**: Dimalanta, Miles C.

---

## Troubleshooting

### Common Issues

#### Issue: "Firebase initialization error"
**Solution:**
Ensure you have successfully run `flutterfire configure` and that the generated `firebase_options.dart` exists in your `lib/` directory.

#### Issue: "CocoaPods not installed" or iOS build failures
**Solution:**
This project primarily targets Android 12+ physical devices as per current scope. If testing on iOS, ensure CocoaPods is installed and you run `pod install` within the `ios/` directory.

#### Issue: "Data not persisting"
**Solution:**
Check your device's network connection and verify that your Firestore security rules allow the necessary read/write operations for your device UUID. Offline persistence is supported, but you must sync online at least once.

#### Issue: "API Key is missing" or "GEMINI_API_KEY is not set"
**Solution:**
Ensure you have created a `lib/config/secrets.dart` file (this file is ignored in version control for security) and defined `const String geminiApiKey = "YOUR_API_KEY";` inside it. We avoid using `.env` files and `dart-define` to ensure hot reloads and IDE play buttons work effortlessly without manual argument passing.

#### Issue: "Gemini API returns a 404 (Model not found)"
**Solution:**
Older API keys may lack access to certain legacy models like `gemini-1.5-flash` or `gemini-2.5-flash`. We resolved this by explicitly targeting the newer supported preview model, `gemini-3.6-flash`. If you encounter a 404, check your Google AI Studio dashboard or run a Python script to list the models available to your specific key.

---

<p align="center">Made with care by the Iskeddy Team</p>
<p align="center">© 2026 Iskeddy. All rights reserved.</p>