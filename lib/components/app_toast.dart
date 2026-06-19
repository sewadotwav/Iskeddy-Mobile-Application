import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_text_styles.dart';

class AppToast {
  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 90,
        left: 24,
        right: 24,
        child: _AnimatedToastBubble(
          message: message,
          onDismiss: () => entry.remove(),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2400), () {
      try { entry.remove(); } catch (_) {}
    });
  }
}

class _AnimatedToastBubble extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _AnimatedToastBubble({required this.message, required this.onDismiss});

  @override
  State<_AnimatedToastBubble> createState() => _AnimatedToastBubbleState();
}

class _AnimatedToastBubbleState extends State<_AnimatedToastBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.message,
                    overflow: TextOverflow.ellipsis,
                    style: appFont(fontSize: 13, fontWeight: FontWeight.w600).copyWith(
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
