import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';


class DeviceIdService {
  static const String _key = 'device_id';

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? existingId = prefs.getString(_key);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final newId = const Uuid().v4();
    await prefs.setString(_key, newId);
    return newId;
  }
}