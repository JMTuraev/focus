import 'package:flutter/material.dart';

import '../backup/backup_crypto.dart';
import '../backup/backup_service.dart';
import '../backup/backup_transport.dart';
import '../data/format.dart';
import '../l10n/l10n.dart';
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
      setState(() => _passError = context.s.backup.passwordsDontMatch);
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
      showToast(context, (w) => SnackBar(width: w < 460 ? w : 460, content: Text(context.s.backup.saved)));
      await _loadList();
    } on BackupException catch (e) {
      if (mounted) showToast(context, (w) => SnackBar(width: w < 460 ? w : 460, content: Text(e.message)));
    }
  }

  Future<void> _restore(BackupEntry e) async {
    final c = context.fc;
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.panel,
        title: Text(s.backup.restoreTitle, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          s.backup.restoreBody(_when(e.date)),
          style: TextStyle(color: c.text2, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.common.cancel, style: TextStyle(color: c.text2))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(s.backup.restore, style: TextStyle(color: c.danger))),
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
          showToast(context, (w) => SnackBar(width: w < 460 ? w : 460, content: Text(context.s.backup.restored(_when(e.date)))));
        }
        return;
      } on NeedPasswordException {
        if (!mounted) return;
        password = await _askPassword(null);
        if (password == null) return;
      } on BackupException catch (err) {
        if (!mounted) return;
        if (password != null && err is WrongPasswordException) {
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
    final s = context.s;
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.panel,
        title: Text(s.backup.passwordTitle, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          onSubmitted: (v) => Navigator.pop(context, v),
          style: TextStyle(color: c.text),
          decoration: InputDecoration(
            hintText: s.backup.askPasswordHint,
            hintStyle: TextStyle(color: c.text2),
            errorText: error,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.common.cancel, style: TextStyle(color: c.text2))),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            child: Text(s.common.open),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final s = context.s;
    return ListenableBuilder(
      listenable: b,
      builder: (context, _) => AlertDialog(
        backgroundColor: c.panel,
        title: Text(s.backup.title, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
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
            child: Text(s.common.close),
          ),
        ],
      ),
    );
  }

  Widget _passwordForm(FokusColors c) {
    final s = context.s;
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
          s.backup.intro,
          style: TextStyle(color: c.textSoft, fontSize: 13.5, height: 1.45),
        ),
        if (_changing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(s.backup.passwordChangeNote, style: TextStyle(color: c.waitingStrong, fontSize: 13)),
          ),
        const SizedBox(height: 14),
        TextField(controller: _pass, obscureText: true, autofocus: true, style: TextStyle(color: c.text), decoration: deco(s.backup.newPasswordHint(BackupService.minPasswordLength))),
        const SizedBox(height: 8),
        TextField(
          controller: _pass2,
          obscureText: true,
          onSubmitted: (_) => _savePassword(),
          style: TextStyle(color: c.text),
          decoration: deco(s.backup.repeatPasswordHint),
        ),
        if (_passError != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(_passError!, style: TextStyle(color: c.danger, fontSize: 13))),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            if (_changing)
              TextButton(onPressed: () => setState(() => _changing = false), child: Text(s.common.cancel, style: TextStyle(color: c.text2))),
            FilledButton(
              onPressed: _savingPassword ? null : _savePassword,
              style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
              child: _savingPassword
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(s.backup.savePassword),
            ),
          ],
        ),
      ],
    );
  }

  Widget _main(FokusColors c) {
    final s = context.s;
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
                last == null ? s.backup.noBackupYet : s.backup.lastBackup(_when(last)),
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
              label: Text(s.backup.backupNow),
              style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: b.autoDaily,
          onChanged: b.setAutoDaily,
          activeThumbColor: Colors.white,
          activeTrackColor: c.accentStrong,
          title: Text(s.backup.autoDaily, style: TextStyle(color: c.text, fontSize: 14)),
          subtitle: Text(s.backup.autoDailyHint, style: TextStyle(color: c.text2, fontSize: 12.5)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _changing = true),
            style: TextButton.styleFrom(foregroundColor: c.accentText, padding: EdgeInsets.zero),
            child: Text(s.backup.changePassword),
          ),
        ),
        Divider(color: c.border, height: 24),
        Row(
          children: [
            Expanded(
              child: Text(s.backup.listTitle, style: TextStyle(color: c.text2, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: s.backup.refresh,
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
          Text(s.backup.listEmpty, style: TextStyle(color: c.text2, fontSize: 13))
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
                    child: Text(s.backup.restore),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
