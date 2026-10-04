import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../donate/donate_info.dart';
import '../theme.dart';

/// Opens a link outside the app. Tests replace it.
typedef LinkOpener = Future<bool> Function(Uri url);

Future<bool> _launch(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);

/// "Fokus’ni qo‘llab-quvvatlash": voluntary donations and other ways to help.
Future<void> showDonateDialog(BuildContext context, {DonateInfo? info, LinkOpener? open}) {
  return showDialog<void>(
    context: context,
    builder: (_) => DonateDialog(info: info ?? DonateInfo.fromEnvironment(), open: open ?? _launch),
  );
}

class DonateDialog extends StatefulWidget {
  const DonateDialog({super.key, required this.info, required this.open});

  final DonateInfo info;
  final LinkOpener open;

  @override
  State<DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<DonateDialog> {
  bool _copied = false;
  String? _error;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyCard() async {
    await Clipboard.setData(ClipboardData(text: widget.info.cardDigits));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _open(Uri url) async {
    var ok = false;
    try {
      ok = await widget.open(url);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _error = ok ? null : 'Havolani ochib bo‘lmadi: ${url.host}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final info = widget.info;
    final card = info.cardNumber;
    final telegram = info.telegramUrl;

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(t, style: TextStyle(color: c.text2, fontSize: 12.5, fontWeight: FontWeight.w700)),
        );
    Widget tile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
      Widget? trailing,
    }) =>
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          hoverColor: c.hover,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: c.accentText),
          ),
          title: Text(title, style: TextStyle(color: c.text, fontSize: 14.5, fontWeight: FontWeight.w600)),
          subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: c.text2, fontSize: 12.5)),
          trailing: trailing ?? Icon(Icons.open_in_new, size: 18, color: c.text2),
          onTap: onTap,
        );

    return AlertDialog(
      backgroundColor: c.panel,
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(Icons.favorite, size: 21, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Fokus’ni qo‘llab-quvvatlash',
                style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Fokus bepul, reklamasiz va serversiz ishlaydi: ma’lumotlaringiz faqat kompyuteringizda va '
                'Telegram’ingizda turadi. Donatlar yangi imkoniyatlar ustida ishlashga vaqt ajratishga yordam beradi.',
                style: TextStyle(color: c.textSoft, fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 8),
              Text(
                'Donat ixtiyoriy. Hech bir imkoniyat pullik emas va donatsiz ham yopilmaydi.',
                style: TextStyle(color: c.text2, fontSize: 12.5, height: 1.4),
              ),
              label('Donat qilish'),
              if (!info.hasPayment)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'To‘lov usullari hali qo‘shilmagan. Tez orada shu yerda paydo bo‘ladi.',
                    style: TextStyle(color: c.text2, fontSize: 13.5),
                  ),
                ),
              if (card != null)
                tile(
                  icon: Icons.credit_card,
                  title: info.cardLabel.trim().isEmpty ? 'Bank kartasi' : info.cardLabel.trim(),
                  subtitle: [card, if (info.cardHolder.trim().isNotEmpty) info.cardHolder.trim()].join('\n'),
                  onTap: _copyCard,
                  trailing: TextButton.icon(
                    onPressed: _copyCard,
                    style: TextButton.styleFrom(foregroundColor: c.accentText),
                    icon: Icon(_copied ? Icons.check : Icons.copy, size: 17),
                    label: Text(_copied ? 'Nusxalandi' : 'Nusxalash'),
                  ),
                ),
              for (final l in info.links)
                tile(
                  icon: switch (l.kind) {
                    DonateKind.payme || DonateKind.click => Icons.account_balance_wallet_outlined,
                    DonateKind.tirikchilik => Icons.volunteer_activism_outlined,
                    DonateKind.other => Icons.public,
                  },
                  title: l.label,
                  subtitle: l.url.host,
                  onTap: () => _open(l.url),
                ),
              label('Boshqa yo‘llar bilan yordam'),
              tile(
                icon: Icons.star_border,
                title: 'GitHub’da yulduzcha qo‘yish',
                subtitle: 'Loyiha ko‘proq odamga ko‘rinadi',
                onTap: () => _open(Uri.parse(AppConfig.repoUrl)),
              ),
              tile(
                icon: Icons.bug_report_outlined,
                title: 'Xato yoki taklif yozish',
                subtitle: 'GitHub Issues',
                onTap: () => _open(Uri.parse('${AppConfig.repoUrl}/issues/new')),
              ),
              if (telegram != null)
                tile(
                  icon: Icons.campaign_outlined,
                  title: 'Yangiliklar kanali',
                  subtitle: telegram.host + telegram.path,
                  onTap: () => _open(telegram),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: TextStyle(color: c.danger, fontSize: 13)),
                ),
              const SizedBox(height: 14),
              Text('Rahmat!', style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
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
