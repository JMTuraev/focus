import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';

class MessageMenuAction {
  const MessageMenuAction(this.value, this.icon, this.label,
      {this.destructive = false});
  final String value;
  final IconData icon;
  final String label;
  final bool destructive;
}

/// Prefer free space beside the selected bubble. On narrow windows, use the
/// space above/below it, keeping the menu inside the chat's history viewport.
Rect messageMenuRect(Rect bubble, Rect viewport, Size size, Offset pointer) {
  final area = viewport.deflate(8);
  final width = math.min(size.width, area.width);
  final height = math.min(size.height, area.height);
  final left = bubble.left - 8 - width;
  final right = bubble.right + 8;
  final fitsLeft = left >= area.left;
  final fitsRight = right + width <= area.right;
  double x;
  double y = pointer.dy - 20;
  if (fitsLeft || fitsRight) {
    x = fitsLeft && (!fitsRight || bubble.center.dx >= area.center.dx)
        ? left
        : right;
  } else {
    x = bubble.center.dx - width / 2;
    final below = area.bottom - bubble.bottom - 8;
    final above = bubble.top - area.top - 8;
    y = below >= height || below >= above
        ? bubble.bottom + 8
        : bubble.top - height - 8;
  }
  return Rect.fromLTWH(x.clamp(area.left, area.right - width).toDouble(),
      y.clamp(area.top, area.bottom - height).toDouble(), width, height);
}

Future<String?> showMessageMenu(
  BuildContext context, {
  required BuildContext anchor,
  required BuildContext viewport,
  required Offset pointer,
  required List<MessageMenuAction> actions,
  required ValueChanged<ModalRoute<dynamic>?> onRoute,
}) {
  final c = context.fc;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  Rect bounds(BuildContext target) {
    final box = target.findRenderObject()! as RenderBox;
    return overlay.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
  }

  final initialAnchor = bounds(anchor);
  final initialViewport = bounds(viewport);
  final menuWidth = math.min(260.0, initialViewport.width - 16);
  final menuHeight = actions.length * 40.0 + 16;
  return showMenu<String>(
    context: context,
    color: c.popover,
    surfaceTintColor: Colors.transparent,
    elevation: 12,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border)),
    constraints: BoxConstraints(
        minWidth: menuWidth,
        maxWidth: menuWidth,
        maxHeight: math.max(40, initialViewport.height - 16)),
    menuPadding: const EdgeInsets.symmetric(vertical: 8),
    positionBuilder: (_, __) {
      final rect = messageMenuRect(
          anchor.mounted ? bounds(anchor) : initialAnchor,
          viewport.mounted ? bounds(viewport) : initialViewport,
          Size(menuWidth, menuHeight),
          overlay.globalToLocal(pointer));
      return RelativeRect.fromRect(rect, Offset.zero & overlay.size);
    },
    items: [
      for (final action in actions)
        PopupMenuItem<String>(
          value: action.value,
          height: 40,
          child: Builder(builder: (itemContext) {
            onRoute(ModalRoute.of(itemContext));
            final color = action.destructive ? c.danger : c.text;
            return Row(children: [
              Icon(action.icon,
                  size: 18, color: action.destructive ? c.danger : c.icon),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(action.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w500))),
            ]);
          }),
        )
    ],
  );
}
