import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_model.dart';
import '../models/course_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _schedulesRef(String deviceId) =>
      _db.collection('devices').doc(deviceId).collection('schedules');

  CollectionReference<Map<String, dynamic>> _coursesRef(
          String deviceId, String scheduleId) =>
      _schedulesRef(deviceId).doc(scheduleId).collection('courses');

  // ── Schedules ──────────────────────────────────────────────

  Stream<List<Schedule>> getSchedulesStream(String deviceId) {
    return _schedulesRef(deviceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Schedule.fromMap(d.data())).toList());
  }

  Future<String> createSchedule(String deviceId, String name) async {
    final id = const Uuid().v4();
    await _schedulesRef(deviceId).doc(id).set({
      'id': id,
      'name': name,
      'isPinned': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Future<void> updateScheduleName(
      String deviceId, String scheduleId, String name) async {
    await _schedulesRef(deviceId).doc(scheduleId).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSchedule(String deviceId, String scheduleId) async {
    final courses = await _coursesRef(deviceId, scheduleId).get();
    final batch = _db.batch();
    for (final doc in courses.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_schedulesRef(deviceId).doc(scheduleId));
    await batch.commit();
  }

  Future<void> deleteMultipleSchedules(
      String deviceId, List<String> scheduleIds) async {
    for (final id in scheduleIds) {
      await deleteSchedule(deviceId, id);
    }
  }

  Future<void> pinSchedule(String deviceId, String scheduleId) async {
    final ref = _schedulesRef(deviceId);
    final batch = _db.batch();

    final currentlyPinned =
        await ref.where('isPinned', isEqualTo: true).get();
    for (final doc in currentlyPinned.docs) {
      batch.update(doc.reference, {
        'isPinned': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    batch.update(ref.doc(scheduleId), {
      'isPinned': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> unpinSchedule(String deviceId, String scheduleId) async {
    await _schedulesRef(deviceId).doc(scheduleId).update({
      'isPinned': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Schedule?> getPinnedSchedule(String deviceId) async {
    final result = await _schedulesRef(deviceId)
        .where('isPinned', isEqualTo: true)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;
    return Schedule.fromMap(result.docs.first.data());
  }

  // ── Courses ────────────────────────────────────────────────

  Stream<List<Course>> getCoursesStream(String deviceId, String scheduleId) {
    return _coursesRef(deviceId, scheduleId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Course.fromMap(d.data())).toList());
  }

  Future<void> addCourse(
      String deviceId, String scheduleId, Course course) async {
    final data = course.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _coursesRef(deviceId, scheduleId).doc(course.id).set(data);
  }

  Future<void> updateCourse(
      String deviceId, String scheduleId, Course course) async {
    final data = course.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _coursesRef(deviceId, scheduleId).doc(course.id).set(data);
  }

  Future<void> deleteCourse(
      String deviceId, String scheduleId, String courseId) async {
    await _coursesRef(deviceId, scheduleId).doc(courseId).delete();
  }

  Future<void> deleteMultipleCourses(
      String deviceId, String scheduleId, List<String> courseIds) async {
    if (courseIds.isEmpty) return;

    final batch = _db.batch();
    final collectionRef = _coursesRef(deviceId, scheduleId);

    for (final id in courseIds) {
      batch.delete(collectionRef.doc(id));
    }

    await batch.commit();
  }
}