/// Where people can send a donation. Values come from build-time defines
/// (`secrets.json`, see `secrets.example.json`) so personal payment details
/// never land in the public repository. Empty values are simply not shown.
///
/// Donations are voluntary: they never unlock a feature.
class DonateInfo {
  const DonateInfo({
    this.card = '',
    this.cardHolder = '',
    this.cardLabel = '',
    this.payme = '',
    this.click = '',
    this.tirikchilik = '',
    this.otherUrl = '',
    this.otherLabel = '',
    this.telegram = '',
  });

  factory DonateInfo.fromEnvironment() => const DonateInfo(
        card: String.fromEnvironment('DONATE_CARD'),
        cardHolder: String.fromEnvironment('DONATE_CARD_HOLDER'),
        cardLabel: String.fromEnvironment('DONATE_CARD_LABEL'),
        payme: String.fromEnvironment('DONATE_PAYME_URL'),
        click: String.fromEnvironment('DONATE_CLICK_URL'),
        tirikchilik: String.fromEnvironment('DONATE_TIRIKCHILIK_URL'),
        otherUrl: String.fromEnvironment('DONATE_OTHER_URL'),
        otherLabel: String.fromEnvironment('DONATE_OTHER_LABEL'),
        telegram: String.fromEnvironment('DONATE_TELEGRAM_URL'),
      );

  final String card;
  final String cardHolder;
  final String cardLabel;
  final String payme;
  final String click;
  final String tirikchilik;
  final String otherUrl;
  final String otherLabel;
  final String telegram;

  /// Card number in groups of four, or null when it is missing or invalid.
  String? get cardNumber {
    final digits = card.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\d{12,19}$').hasMatch(digits)) return null;
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, i + 4 > digits.length ? digits.length : i + 4));
    }
    return groups.join(' ');
  }

  /// Card digits without spaces, for the clipboard.
  String get cardDigits => cardNumber?.replaceAll(' ', '') ?? '';

  /// Payment links that are valid https URLs, in display order.
  List<DonateLink> get links => [
        for (final (kind, label, url) in [
          (DonateKind.payme, 'Payme', payme),
          (DonateKind.click, 'Click', click),
          (DonateKind.tirikchilik, 'Tirikchilik', tirikchilik),
          (DonateKind.other, otherLabel.trim().isEmpty ? 'Xalqaro to‘lov' : otherLabel.trim(), otherUrl),
        ])
          if (safeUrl(url) case final uri?) DonateLink(kind, label, uri),
      ];

  /// The project's Telegram channel, if set.
  Uri? get telegramUrl => safeUrl(telegram);

  bool get hasPayment => cardNumber != null || links.isNotEmpty;

  /// Only https links with a host are opened.
  static Uri? safeUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}

enum DonateKind { payme, click, tirikchilik, other }

class DonateLink {
  const DonateLink(this.kind, this.label, this.url);

  final DonateKind kind;
  final String label;
  final Uri url;
}
