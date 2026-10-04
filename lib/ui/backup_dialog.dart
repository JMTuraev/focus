import 'package:flutter/material.dart';

import '../backup/backup_crypto.dart';
import '../backup/backup_service.dart';
import '../backup/backup_transport.dart';
import '../data/format.dart';
import '../theme.dart';
import 'common.dart';

/// Encrypted backups to Saved Messages: password, back up now, daily
/// backups, and restoring an earlier backup.
Future<void> showBackupDialog(BuildContext context, BackupService backup, {required Future<void> Function() onRestored}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _BackupDialog(backup: backup, onRestored: onRestored),
  );
}

String _when(DateTime d) => '${Fmt.dueLabel(d)}, ${Fmt.hm(d)}';

class _BackupDialog extends StatefulWidget {
  const _BackupDialog({required this.backup, required this.onRestored});

  final BackupService backup;
  final Future<void> Function() onRestored;

  @override
  State<_BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<_BackupDialog> {
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _changing = false;
  bool _savingPassword = false;
  String? _passError;
  List<BackupEntry>? _entries;
  bool _listing = false;
  String? _listError;

  BackupService get b => widget.backup;

  @override
  void initState() {
    super.initState();
    if (b.hasPassword) _loadList();
  }

  @override
  void dispose() {
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() {
      _listing = true;
      _listError = null;
    });
    try {
      final list = await b.list();
      if (mounted) setState(() => _entries = list);
    } on BackupException catch (e) {
      if (mounted) setState(() => _listError = e.message);
    } finally {
      if (mounted) setState(() => _listing = false);
    }
  }

  Future<void> _savePassword() async {
    if (_pass.text != _pass2.text) {
      setState(() => _passError = 'Parollar bir xil emas.');
      return;
    }
    setState(() {
      _savingPassword = true;
      _passError = null;
    });
    try {
      await b.setPassword(_pass.text);
      _pass.clear();
      _pass2.clear();
      if (mounted) setState(() => _changing = false);
      await _loadList();
    } on BackupException catch (e) {
      if (mounted) setState(() => _passError = e.message);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _backupNow() async {
    try {
      await b.backupNow();
      if (!mounted) return;
      showToast(context, (w) => SnackBar(width: w < 460 ? w : 460, content: const Text('Zaxira nusxa Saved Messages’ga saqlandi')));
      await _loadList();
    } on BackupException catch (e) {
      if (mounted) showToast(context, (w) => SnackBar(width: w < 460 ? w : 460, content: Text(e.message)));
    }
  }

  Future<void> _restore(BackupEntry e) async {
    final c = context.fc;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.panel,
        title: Text('Shu nusxani tiklaysizmi?', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          '${_when(e.date)} dagi nusxa. Hozirgi vazifalar, kalendar, eslatmalar va to‘plamlar shu nusxadagisi bilan almashtiriladi. '
          'Telegram chatlariga ta’sir qilmaydi.',
          style: TextStyle(color: c.text2, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Bekor qilish', style: TextStyle(color: c.text2))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Tiklash', style: TextStyle(color: c.danger))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    String? password;
    while (true) {
      try {
        await b.restore(e, password: password);
        await widget.onRestored();
        if (mounted) {
          showToast(context, (w) => SnackBar(width: w < 460 ? w : 460, content: Text('${_when(e.date)} dagi nusxa tiklandi')));
        }
        return;
      } on NeedPasswordException {
        if (!mounted) return;
        password = await _askPassword(null);
        if (password == null) return;
      } on BackupException catch (err) {
        if (!mounted) return;
        if (password != null && err.message.startsWith('Parol')) {
          password = await _askPassword(err.message);
          if (password == null) return;
        } else {
          showToast(context, (w) => SnackBar(width: w < 460 ? w : 460, content: Text(err.message)));
          return;
        }
      }
    }
  }

  Future<String?> _askPassword(String? error) {
    final c = context.fc;
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.panel,
        title: Text('Zaxira paroli', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          onSubmitted: (v) => Navigator.pop(context, v),
          style: TextStyle(color: c.text),
          decoration: InputDecoration(
            hintText: 'Nusxa yaratilgandagi parol',
            hintStyle: TextStyle(color: c.text2),
            errorText: error,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Bekor qilish', style: TextStyle(color: c.text2))),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            child: const Text('Ochish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return ListenableBuilder(
      listenable: b,
      builder: (context, _) => AlertDialog(
        backgroundColor: c.panel,
        title: Text('Zaxira nusxa', style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: !b.hasPassword || _changing ? _passwordForm(c) : _main(c),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  Widget _passwordForm(FokusColors c) {
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.text2),
          filled: true,
          fillColor: c.bg,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.chipBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.chipBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.accent, width: 2)),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vazifalar, kalendar, eslatmalar va to‘plamlar shifrlanib, Telegram’dagi Saved Messages’ga saqlanadi. '
          'Ochish uchun alohida zaxira paroli kerak. Uni faqat siz bilasiz: parolni unutsangiz, nusxani hech kim, '
          'hatto biz ham ocha olmaymiz.',
          style: TextStyle(color: c.textSoft, fontSize: 13.5, height: 1.45),
        ),
        if (_changing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Eski nusxalar eski parol bilan ochiladi.', style: TextStyle(color: c.waitingStrong, fontSize: 13)),
          ),
        const SizedBox(height: 14),
        TextField(controller: _pass, obscureText: true, autofocus: true, style: TextStyle(color: c.text), decoration: deco('Zaxira paroli (kamida 8 belgi)')),
        const SizedBox(height: 8),
        TextField(
          controller: _pass2,
          obscureText: true,
          onSubmitted: (_) => _savePassword(),
          style: TextStyle(color: c.text),
          decoration: deco('Parolni takrorlang'),
        ),
        if (_passError != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_passError!, style: TextStyle(color: c.danger, fontSize: 13))),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_changing)
              TextButton(onPressed: () => setState(() => _changing = false), child: Text('Bekor qilish', style: TextStyle(color: c.text2))),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _savingPassword ? null : _savePassword,
              style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
              child: _savingPassword
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Parolni saqlash'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _main(FokusColors c) {
    final last = b.lastBackupAt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: c.localFg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                last == null ? 'Hali zaxira nusxa saqlanmagan' : 'Oxirgi nusxa: ${_when(last)}',
                style: TextStyle(color: c.text, fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (b.lastError != null)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(b.lastError!, style: TextStyle(color: c.danger, fontSize: 13))),
        const SizedBox(height: 12),
        if (b.busy) ...[
          Text(b.status ?? '', style: TextStyle(color: c.text2, fontSize: 13)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: b.progress, color: c.accent, backgroundColor: c.bg, minHeight: 6, borderRadius: BorderRadius.circular(3)),
        ] else
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _backupNow,
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('Hozir saqlash'),
              style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: b.autoDaily,
          onChanged: b.setAutoDaily,
          activeThumbColor: Colors.white,
          activeTrackColor: c.accentStrong,
          title: Text('Har kuni avtomatik saqlash', style: TextStyle(color: c.text, fontSize: 14)),
          subtitle: Text('Focus ochiq bo‘lganda, kuniga bir marta', style: TextStyle(color: c.text2, fontSize: 12.5)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _changing = true),
            style: TextButton.styleFrom(foregroundColor: c.accentText, padding: EdgeInsets.zero),
            child: const Text('Parolni o‘zgartirish'),
          ),
        ),
        Divider(color: c.border, height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Saved Messages’dagi nusxalar', style: TextStyle(color: c.text2, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Yangilash',
              onPressed: _listing ? null : _loadList,
              icon: Icon(Icons.refresh, size: 18, color: c.icon),
            ),
          ],
        ),
        if (_listing && _entries == null)
          const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)))
        else if (_listError != null)
          Text(_listError!, style: TextStyle(color: c.danger, fontSize: 13))
        else if ((_entries ?? const []).isEmpty)
          Text('Hali nusxa yo‘q.', style: TextStyle(color: c.text2, fontSize: 13))
        else
          for (final e in _entries!.take(10))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, size: 18, color: c.icon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${_when(e.date)} · ${Fmt.size(e.size)}', style: TextStyle(color: c.text, fontSize: 13.5)),
                  ),
                  TextButton(
                    onPressed: b.busy ? null : () => _restore(e),
                    style: TextButton.styleFrom(foregroundColor: c.accentText),
                    child: const Text('Tiklash'),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
