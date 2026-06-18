import 'package:flutter/material.dart';
import '../../components/app_header.dart';

class DefaultTimetableScreen extends StatelessWidget {
  const DefaultTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 24.0),
              child: AppHeader(),
            ),
            const Expanded(
              child: Center(
                child: Text('Default Timetable Screen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
