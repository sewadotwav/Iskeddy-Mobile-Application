# Iskeddy - Class Schedule Maker (Personal Learning Project)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Platform-Android_12+-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License">
</p>

A clean, manual class schedule maker designed for students, built with modern Flutter and Firebase technologies. The application allows students to create and manage multiple schedules, add and edit course entries, and view their courses through an intuitive card-based list grouped by day, without the clutter of a traditional calendar grid.

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
- **Course Management** - Add detailed course entries including meeting times, room numbers, and instructors.
- **Visual Organization** - Choose from a curated 10-color fixed palette to visually organize classes.
- **Flexible Class Modes** - Support for onsite, synchronous, and asynchronous learning blocks.
- **Frictionless Experience** - No login, no accounts, and no authentication required. Identity is managed transparently via device UUID.
- **Clean Interface** - A card-based list approach grouped by day, bypassing the visual constraints of a calendar grid.
- **Offline Persistence** - Firestore offline capabilities to view and manage schedules without an internet connection.
- **Future Ready** - A later phase adds AI-powered OCR using Gemini to auto-plot a schedule from an uploaded image.

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
│   ├── models/        # Data models (Course, Schedule, MeetingTime)
│   ├── screens/       # Core application screens (Tabs, Details)
│   ├── services/      # Device ID and Firestore services
│   ├── utils/         # Helper functions (time parsing, etc.)
│   ├── components/    # Shared reusable UI components
│   ├── app.dart       # MaterialApp and routing
│   └── main.dart      # Application entry point
├── android/           # Android-specific build configurations
├── assets/            # Fonts and static assets
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

---

## Recent Updates

- **Navigation Shell**: Implemented robust tab-based navigation using an `IndexedStack` to persist state between the Default Timetable and All Schedules tabs.
- **Shared Components**: Built a comprehensive reusable component library including dialogs, pills, circular buttons, and dynamic cards to maintain visual consistency.
- **Data Architecture**: Finalized Firestore schema and strict security rules to enforce data integrity without requiring traditional user accounts.
- **Course Editor**: Developed an intuitive bottom sheet interface capable of handling both course creation and modification with dynamic time block management.

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

---

<p align="center">Made with care by the Iskeddy Team</p>
<p align="center">© 2026 Iskeddy. All rights reserved.</p>