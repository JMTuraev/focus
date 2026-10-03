import 'package:flutter/material.dart';

import '../theme.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials, required this.color, this.size = 50, this.online = false});

  final String initials;
  final Color color;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              initials,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.32),
            ),
          ),
          if (online)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration: BoxDecoration(
                  color: FC.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.muted = false, this.inverted = false});

  final int count;
  final bool muted;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final bg = inverted ? Colors.white : (muted ? FC.muted : FC.accentStrong);
    final fg = inverted ? FC.accentStrong : Colors.white;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
      child: Text('$count', style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class WaitingDot extends StatelessWidget {
  const WaitingDot({super.key, this.ring = false});

  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Javob kutmoqda',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: FC.waiting,
          shape: BoxShape.circle,
          border: ring ? Border.all(color: Colors.white, width: 2) : null,
        ),
      ),
    );
  }
}

/// Rounded hoverable surface used for list rows and chips.
class Tap extends StatelessWidget {
  const Tap({
    super.key,
    required this.onTap,
    required this.child,
    this.color = Colors.transparent,
    this.hover = FC.hover,
    this.radius = 10,
    this.border,
  });

  final VoidCallback? onTap;
  final Widget child;
  final Color color;
  final Color hover;
  final double radius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: r),
      child: Ink(
        decoration: BoxDecoration(borderRadius: r, border: border),
        child: InkWell(
          borderRadius: r,
          hoverColor: hover,
          highlightColor: hover,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// Light doodle-like dot pattern for the chat background.
class WallpaperPainter extends CustomPainter {
  const WallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = FC.wallpaper);
    final light = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final dark = Paint()..color = const Color(0xFF466E32).withValues(alpha: 0.13);
    for (double y = 0; y < size.height + 52; y += 52) {
      for (double x = 0; x < size.width + 48; x += 48) {
        canvas.drawCircle(Offset(x + 10, y + 10), 2.2, light);
        canvas.drawCircle(Offset(x + 34, y + 30), 3, dark);
        canvas.drawCircle(Offset(x + 22, y + 44), 1.6, light);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
