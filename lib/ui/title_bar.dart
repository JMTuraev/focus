import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../state/settings.dart';
import '../theme.dart';
import 'donate_dialog.dart';
import '../l10n/l10n.dart';

/// Custom Windows title bar: logo, local-mode badge, donation and theme
/// buttons, window controls.
class FokusTitleBar extends StatelessWidget {
  const FokusTitleBar({super.key, required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final t = context.s.app;
    // Russian and English badge texts are longer than Uzbek.
    final wide = settings.language == AppLanguage.uz ? 760 : 980;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: c.titleBar,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const FokusLogo(size: 20),
                  // The name gives way to the buttons in very narrow windows.
                  if (width >= 520) ...[
                    const SizedBox(width: 8),
                    Text('Focus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                  ],
                  const Spacer(),
                  LocalModeBadge(compact: width < wide, iconOnly: width < 600),
                  const Spacer(),
                ],
              ),
            ),
          ),
          _WinButton(
            icon: Icons.favorite_border,
            label: t.donate,
            tooltip: t.supportFocus,
            onTap: () => showDonateDialog(context),
          ),
          _LanguageButton(settings: settings),
          _WinButton(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: isDark ? t.lightMode : t.darkMode,
            tooltip: isDark ? t.toLightMode : t.toDarkMode,
            onTap: () => settings.toggleTheme(brightness),
          ),
          _WinButton(icon: Icons.remove, label: t.minimize, onTap: () => windowManager.minimize()),
          _WinButton(
            icon: Icons.crop_square,
            label: t.maximize,
            onTap: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _WinButton(icon: Icons.close, label: context.s.common.close, danger: true, onTap: () => windowManager.close()),
        ],
      ),
    );
  }
}

/// Title bar button with the three UI languages (also on the login screen).
class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.app;
    return _WinButton(
      icon: Icons.translate,
      label: t.language,
      tooltip: t.changeLanguage,
      onTapAt: (pos) async {
        final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
        final picked = await showMenu<AppLanguage>(
          context: context,
          color: c.panel,
          position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
          items: [
            for (final l in AppLanguage.values)
              PopupMenuItem(
                value: l,
                height: 38,
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: l == settings.language ? Icon(Icons.check, size: 17, color: c.accent) : null,
                    ),
                    Text(l.nativeName, style: TextStyle(color: c.text, fontSize: 14)),
                  ],
                ),
              ),
          ],
        );
        if (picked != null) settings.setLanguage(picked);
      },
    );
  }
}

class FokusLogo extends StatelessWidget {
  const FokusLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.width * 0.3));
    canvas.drawRRect(r, Paint()..color = FokusColors.brand);
    final c = s.center(Offset.zero);
    canvas.drawCircle(
      c,
      s.width * 0.25,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * 0.09,
    );
    canvas.drawCircle(c, s.width * 0.085, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LocalModeBadge extends StatelessWidget {
  const LocalModeBadge({super.key, this.compact = false, this.iconOnly = false});

  /// Narrow windows show a short label (or only the icon); the full text
  /// stays in the tooltip.
  final bool compact;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Tooltip(
      message: context.s.app.localModeTip,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: c.localBg, borderRadius: BorderRadius.circular(11)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, size: 13, color: c.localFg),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(
                compact ? context.s.app.localMode : context.s.app.localModeLong,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.localFg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WinButton extends StatefulWidget {
  const _WinButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.onTapAt,
    this.danger = false,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Like [onTap], with the pointer position (for menus).
  final void Function(Offset globalPosition)? onTapAt;
  final bool danger;
  final String? tooltip;

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final bg = _hover ? (widget.danger ? const Color(0xFFC42B1C) : c.winHover) : Colors.transparent;
    final fg = _hover && widget.danger ? Colors.white : c.textSoft;
    Widget body = Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapUp: widget.onTapAt == null ? null : (d) => widget.onTapAt!(d.globalPosition),
          child: Container(width: 46, height: 36, color: bg, child: Icon(widget.icon, size: 15, color: fg)),
        ),
      ),
    );
    if (widget.tooltip != null) body = Tooltip(message: widget.tooltip!, child: body);
    return body;
  }
}
