import 'package:flutter/material.dart';

import '../backup/backup_service.dart';
import '../config.dart';
import '../data/format.dart';
import '../reminders/notifier.dart';
import '../reminders/reminder_service.dart';
import '../state/settings.dart';
import '../theme.dart';
import 'backup_dialog.dart';
import 'common.dart';
import 'donate_dialog.dart';

/// Settings: theme, reminders (Windows notifications), the hour for task
/// reminders, and the encrypted backup.
Future<void> showSettingsDialog(
  BuildContext context,
  Settings settings, {
  Notifier? notifier,
  ReminderService? reminders,
  BackupService? backup,
  Future<void> Function()? onRestored,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ListenableBuilder(
      listenable: Listenable.merge([settings, if (backup != null) backup]),
      builder: (context, _) => _SettingsDialog(
        settings: settings,
        notifier: notifier,
        reminders: reminders,
        backup: backup,
        onRestored: onRestored,
      ),
    ),
  );
}

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog({required this.settings, this.notifier, this.reminders, this.backup, this.onRestored});

  final Settings settings;
  final Notifier? notifier;
  final ReminderService? reminders;
  final BackupService? backup;
  final Future<void> Function()? onRestored;

  static const _hours = [7, 8, 9, 10, 12, 18];

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final available = notifier != null;
    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(t, style: TextStyle(color: c.text2, fontSize: 12.5, fontWeight: FontWeight.w700)),
        );
    Widget chip(String text, bool selected, VoidCallback? onTap) => ChoiceChip(
          label: Text(text),
          selected: selected,
          onSelected: onTap == null ? null : (_) => onTap(),
          showCheckmark: false,
          labelStyle: TextStyle(color: selected ? Colors.white : c.textSoft, fontWeight: FontWeight.w600, fontSize: 13),
          selectedColor: c.accentStrong,
          backgroundColor: c.panel,
          side: BorderSide(color: selected ? c.accentStrong : c.chipBorder),
        );
    final count = reminders?.scheduled.length ?? 0;

    return AlertDialog(
      backgroundColor: c.panel,
      title: Text('Sozlamalar', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label('Mavzu'),
              Wrap(
                spacing: 6,
                children: [
                  chip('Tizimga mos', settings.themeMode == ThemeMode.system, () => settings.setThemeMode(ThemeMode.system)),
                  chip('Yorug‘', settings.themeMode == ThemeMode.light, () => settings.setThemeMode(ThemeMode.light)),
                  chip('Tungi', settings.themeMode == ThemeMode.dark, () => settings.setThemeMode(ThemeMode.dark)),
                ],
              ),
              label('Eslatmalar'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: available && settings.remindersEnabled,
                onChanged: available ? settings.setRemindersEnabled : null,
                activeThumbColor: Colors.white,
                activeTrackColor: c.accentStrong,
                title: Text('Uchrashuv va vazifa bildirishnomalari', style: TextStyle(color: c.text, fontSize: 14.5)),
                subtitle: Text(
                  available
                      ? 'Windows bildirishnomasi Fokus yopiq bo‘lsa ham o‘z vaqtida chiqadi.'
                      : 'Windows bildirishnomalari bu kompyuterda ishga tushmadi.',
                  style: TextStyle(color: c.text2, fontSize: 12.5),
                ),
              ),
              if (available && settings.remindersEnabled) ...[
                label('Vazifa muddati kuni eslatish vaqti'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final h in _hours)
                      chip('${h.toString().padLeft(2, '0')}:00', settings.taskReminderHour == h, () => settings.setTaskReminderHour(h)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 18, color: c.text2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        count == 0 ? 'Hozircha rejalashtirilgan eslatma yo‘q' : '$count ta eslatma rejalashtirilgan',
                        style: TextStyle(color: c.text2, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await notifier!.show(id: 1, title: 'Fokus', body: 'Bildirishnomalar ishlayapti.');
                        if (context.mounted) {
                          showToast(context, (w) => SnackBar(width: w < 420 ? w : 420, content: const Text('Sinov bildirishnomasi yuborildi')));
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: c.accentText),
                      child: const Text('Sinab ko‘rish'),
                    ),
                  ],
                ),
              ],
              if (backup != null) ...[
                label('Zaxira nusxa'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cloud_done_outlined, color: c.icon),
                  title: Text('Shifrlangan zaxira (Saved Messages)', style: TextStyle(color: c.text, fontSize: 14.5)),
                  subtitle: Text(
                    switch (backup!.lastBackupAt) {
                      null => backup!.hasPassword ? 'Hali saqlanmagan' : 'Sozlanmagan',
                      final d => 'Oxirgi: ${Fmt.dueLabel(d)}, ${Fmt.hm(d)}',
                    },
                    style: TextStyle(color: c.text2, fontSize: 12.5),
                  ),
                  trailing: Icon(Icons.chevron_right, color: c.text2),
                  onTap: () => showBackupDialog(context, backup!, onRestored: onRestored ?? () async {}),
                ),
              ],
              label('Fokus haqida'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.favorite_border, color: c.icon),
                title: Text('Fokus’ni qo‘llab-quvvatlash', style: TextStyle(color: c.text, fontSize: 14.5)),
                subtitle: Text('Donat va boshqa yo‘llar bilan yordam', style: TextStyle(color: c.text2, fontSize: 12.5)),
                trailing: Icon(Icons.chevron_right, color: c.text2),
                onTap: () => showDonateDialog(context),
              ),
              const SizedBox(height: 8),
              Text('Fokus ${AppConfig.version}', style: TextStyle(color: c.text2, fontSize: 12)),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
          child: const Text('Yopish'),
        ),
      ],
    );
  }
}
