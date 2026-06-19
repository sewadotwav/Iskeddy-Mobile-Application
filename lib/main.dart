/*
 * Phase 9 (Polish, Edge Cases & Integration) - COMPLETE
 * 
 * Integration Test Checklist:
 * [x] Flow 1 - Full Create & Add Courses
 * [x] Flow 2 - Edit & Delete Course
 * [x] Flow 3 - Pin & Default Timetable
 * [x] Flow 4 - Rename Schedule
 * [x] Flow 5 - Multi-Select & Bulk Delete
 * [x] Flow 6 - Offline Persistence
 * [x] Flow 7 - Pinned Schedule Deleted While on Screen 1
 */
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If it's already initialized natively, ignore the duplicate app error
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const IskeddyApp());
}