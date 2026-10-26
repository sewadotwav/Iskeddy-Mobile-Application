import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_model.dart';
import '../models/course_model.dart';
import '../models/meeting_time_model.dart';
import 'firestore_service.dart';

class ScheduleShareService {
  /// Option A: Captures a RepaintBoundary key as a high-res PNG and triggers native share sheet
  static Future<bool> shareScheduleImage(
    GlobalKey boundaryKey,
    String scheduleTitle, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('ScheduleShareService: RenderRepaintBoundary not found.');
        return false;
      }

      // Convert layout boundary to image with crisp 3.0 pixelRatio
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to local temporary directory
      final directory = await getTemporaryDirectory();
      final sanitizedTitle = scheduleTitle
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName =
          '${sanitizedTitle.isEmpty ? "schedule" : sanitizedTitle}_timetable.png';
      final filePath = '${directory.path}/$fileName';
      final File imgFile = File(filePath);
      await imgFile.writeAsBytes(pngBytes, flush: true);

      // Trigger native share dialog
      final xFile = XFile(filePath, mimeType: 'image/png');
      await Share.shareXFiles(
        [xFile],
        text: 'Check out my class schedule for "$scheduleTitle" on Iskeddy!',
        sharePositionOrigin: sharePositionOrigin,
      );
      return true;
    } catch (e, stack) {
      debugPrint('Error sharing schedule image: $e\n$stack');
      return false;
    }
  }

  /// Option B: Serializes schedule & courses into a clean Base64 JSON string
  static String exportScheduleToJson(Schedule schedule, List<Course> courses) {
    try {
      final Map<String, dynamic> exportData = {
        'version': 1,
        'app': 'Iskeddy',
        'scheduleName': schedule.name,
        'createdAt': DateTime.now().toIso8601String(),
        'courses': courses
            .map((c) => {
                  'title': c.title,
                  'section': c.section,
                  'colorHex': c.colorHex,
                  'notes': c.notes,
                  'maxAbsences': c.maxAbsences,
                  'absenceCount': c.absenceCount,
                  'lateCount': c.lateCount,
                  'meetingTimes': c.meetingTimes.map((m) => m.toMap()).toList(),
                })
            .toList(),
      };

      final jsonString = jsonEncode(exportData);
      return base64Encode(utf8.encode(jsonString));
    } catch (e, stack) {
      debugPrint('Error encoding schedule JSON: $e\n$stack');
      return '';
    }
  }

  /// Option B: Decodes a Base64 export string back into raw map data for import processing
  static Map<String, dynamic>? importScheduleFromJson(String base64Code) {
    try {
      final trimmed = base64Code.trim();
      if (trimmed.isEmpty) return null;

      final decodedBytes = base64Decode(trimmed);
      final decodedJson = utf8.decode(decodedBytes);
      final dynamic parsed = jsonDecode(decodedJson);

      if (parsed is Map<String, dynamic> && parsed.containsKey('scheduleName')) {
        return parsed;
      }
      return null;
    } catch (e) {
      debugPrint('Error decoding schedule JSON: $e');
      return null;
    }
  }

  /// Converts the raw courses map list from the export data into domain Course models
  static List<Course> parseCoursesFromExport(dynamic rawCourses) {
    if (rawCourses is! List) return [];
    const uuid = Uuid();
    return rawCourses.map((item) {
      final map = item as Map<String, dynamic>;
      final rawTitle = (map['title'] as String? ?? '').trim();
      return Course(
        id: uuid.v4(),
        title: rawTitle.isEmpty ? 'Untitled Course' : rawTitle,
        section: (map['section'] as String? ?? '').trim(),
        colorHex: (map['colorHex'] as String? ?? '#F9E9D0'),
        notes: (map['notes'] as String?)?.trim(),
        meetingTimes: (map['meetingTimes'] as List<dynamic>? ?? [])
            .map((m) => MeetingTime.fromMap(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        maxAbsences: map['maxAbsences'] as int?,
        absenceCount: (map['absenceCount'] as int?) ?? 0,
        lateCount: (map['lateCount'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Connects decoding directly to FirestoreService and domain models,
  /// creating the new imported schedule and all course documents atomically.
  /// Returns the newly created schedule ID on success, or null if the code is invalid.
  static Future<String?> importAndSaveToFirestore({
    required String deviceId,
    required String base64Code,
    FirestoreService? firestoreService,
  }) async {
    final parsedData = importScheduleFromJson(base64Code);
    if (parsedData == null || !parsedData.containsKey('scheduleName')) {
      return null;
    }

    final rawName =
        (parsedData['scheduleName'] as String? ?? 'Schedule').trim();
    final importedName = '$rawName (Imported)';
    final List<Course> courses = parseCoursesFromExport(parsedData['courses']);

    final fs = firestoreService ?? FirestoreService();
    return await fs.createImportedSchedule(deviceId, importedName, courses);
  }
}
