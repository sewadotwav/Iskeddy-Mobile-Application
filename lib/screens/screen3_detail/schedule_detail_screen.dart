import 'package:flutter/material.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final String scheduleId;

  const ScheduleDetailScreen({
    super.key,
    required this.scheduleId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: null,
      ),
      body: const Center(
        child: Text('Schedule Detail Screen'),
      ),
    );
  }
}
