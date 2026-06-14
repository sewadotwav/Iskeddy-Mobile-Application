import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iskeddy/services/device_id_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getDeviceId returns the same value on repeated calls', () async {
    final id1 = await DeviceIdService.getDeviceId();
    final id2 = await DeviceIdService.getDeviceId();

    expect(id1, equals(id2));
    expect(id1.isNotEmpty, true);
  });

  test('getDeviceId returns a valid UUID v4 format', () async {
    final id = await DeviceIdService.getDeviceId();

    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    expect(uuidRegex.hasMatch(id), true);
  });
}