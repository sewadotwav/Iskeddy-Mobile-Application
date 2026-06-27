import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_text_styles.dart';
import '../constants/app_colors.dart';

class DigitalClock extends StatefulWidget {
  const DigitalClock({super.key});

  @override
  State<DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm:ss');
    final amPmFormat = DateFormat('a');
    final dateFormat = DateFormat('MMMM d, yyyy');
    final dayFormat = DateFormat('EEEE');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeFormat.format(_now),
                  style: appFont(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateFormat.format(_now),
                  style: appFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                Text(
                  dayFormat.format(_now),
                  style: appFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amPmFormat.format(_now),
            style: appFont(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: accentColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
