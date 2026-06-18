import 'package:flutter/material.dart';
/// Requires assets/images/app_logo.jpg to be declared under the
/// `flutter: assets:` section of pubspec.yaml.
class AppHeader extends StatelessWidget {
  final double size;

  const AppHeader({super.key, this.size = 35});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/app_logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
