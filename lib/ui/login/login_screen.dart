import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/auth.dart';
import '../../l10n/l10n.dart';
import '../../state/settings.dart';
import '../../theme.dart';
import '../title_bar.dart';

/// Telegram login: phone → code → 2FA password, Telegram Desktop style.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, required this.settings});

  final AuthService auth;
  final Settings settings;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Kept so "Raqamni o‘zgartirish" brings the number back.
  String _phone = '+998';

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Scaffold(
      backgroundColor: c.panel,
      body: Column(
        children: [
          FokusTitleBar(settings: widget.settings),
          Expanded(
            child: ValueListenableBuilder<AuthState>(
              valueListenable: widget.auth.state,
              builder: (context, s, _) => LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Center(
                      child: SizedBox(
                        width: math.min(380, box.maxWidth - 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: KeyedSubtree(key: ObjectKey(s.code ?? s.step), child: _step(s)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(AuthState s) {
    final auth = widget.auth;
    final t = context.s.auth;
    return switch (s.step) {
      AuthStep.starting => _Busy(auth.isMock ? t.loading : t.connecting),
      AuthStep.ready => _Busy(t.signingIn),
      AuthStep.loggingOut => _Busy(t.loggingOut),
      AuthStep.waitPhone => _PhoneStep(
          auth: auth,
          initial: _phone,
          onChanged: (p) => _phone = p,
        ),
      AuthStep.waitCode => _CodeStep(auth: auth, info: s.code!),
      AuthStep.waitPassword => _PasswordStep(auth: auth, hint: s.passwordHint),
      AuthStep.unsupported => _Notice(
          icon: Icons.info_outline,
          title: t.unsupportedTitle,
          message: s.message,
          action: t.otherNumber,
          onAction: auth.editPhone,
        ),
      AuthStep.failed => _Notice(
          icon: Icons.cloud_off_outlined,
          title: t.failedTitle,
          message: s.message,
          action: context.s.common.retry,
          onAction: auth.start,
        ),
    };
  }
}

// ---------------------------------------------------------------- steps

class _PhoneStep extends StatefulWidget {
  const _PhoneStep({required this.auth, required this.initial, required this.onChanged});

  final AuthService auth;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<_PhoneStep> with _Submit {
  late final _ctrl = TextEditingController(text: formatPhone(widget.initial));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final digits = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) {
      setState(() => error = context.s.auth.phoneTooShort);
      return;
    }
    await submit(() => widget.auth.sendPhone(_ctrl.text));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.auth;
    return _Form(
      top: const FokusLogo(size: 76),
      title: t.phoneTitle,
      subtitle: t.phoneSubtitle,
      field: _Field(
        controller: _ctrl,
        enabled: !busy,
        autofocus: true,
        keyboardType: TextInputType.phone,
        inputFormatters: [_PhoneFormatter()],
        onChanged: (v) {
          widget.onChanged(v);
          if (error != null) setState(() => error = null);
        },
        onSubmitted: (_) => _go(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      error: error,
      button: t.next,
      busy: busy,
      onButton: _go,
      mockHint: widget.auth.isMock ? t.mockPhone : null,
    );
  }
}

class _CodeStep extends StatefulWidget {
  const _CodeStep({required this.auth, required this.info});

  final AuthService auth;
  final CodeInfo info;

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<_CodeStep> with _Submit {
  final _ctrl = TextEditingController();
  Timer? _timer;
  late int _left = widget.info.timeout;

  @override
  void initState() {
    super.initState();
    if (_left > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _left--);
        if (_left <= 0) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) {
      setState(() => error = context.s.auth.codeEmpty);
      return;
    }
    await submit(() => widget.auth.sendCode(code));
    if (error != null) _ctrl.clear();
  }

  String get _subtitle {
    final i = widget.info;
    final t = context.s.auth;
    return switch (i.delivery) {
      CodeDelivery.telegram => t.codeViaTelegram,
      CodeDelivery.sms => i.textual ? t.codeSmsWord : t.codeViaSms,
      CodeDelivery.call => t.codeViaCall,
      CodeDelivery.flashCall || CodeDelivery.missedCall => t.codeViaFlashCall,
      CodeDelivery.fragment => t.codeViaFragment,
      CodeDelivery.email => t.codeViaEmail,
      CodeDelivery.other => t.codeSent,
    };
  }

  String? get _resendLabel => switch (widget.info.next) {
        null => null,
        CodeDelivery.sms => context.s.auth.resendViaSms,
        CodeDelivery.call || CodeDelivery.flashCall || CodeDelivery.missedCall => context.s.auth.resendViaCall,
        _ => context.s.auth.resend,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final i = widget.info;
    final resend = _resendLabel;
    final t = context.s.auth;
    return _Form(
      top: const _RoundIcon(Icons.mark_chat_read_outlined),
      title: formatPhone(i.phone),
      titleAction: _Link(t.changeNumber, onTap: busy ? null : widget.auth.editPhone),
      subtitle: _subtitle,
      field: _Field(
        controller: _ctrl,
        enabled: !busy,
        autofocus: true,
        hint: i.textual ? t.codeWordHint : t.codeHint,
        textAlign: TextAlign.center,
        keyboardType: i.textual ? TextInputType.text : TextInputType.number,
        inputFormatters: [
          if (!i.textual) FilteringTextInputFormatter.digitsOnly,
          if (!i.textual && i.length > 0) LengthLimitingTextInputFormatter(i.length),
        ],
        onChanged: (v) {
          if (error != null) setState(() => error = null);
          if (!i.textual && i.length > 0 && v.length == i.length) _go();
        },
        onSubmitted: (_) => _go(),
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: i.textual ? 0.5 : 8),
      ),
      error: error,
      button: t.next,
      busy: busy,
      onButton: _go,
      below: resend == null
          ? null
          : _left > 0
              ? Text('$resend (${_left ~/ 60}:${(_left % 60).toString().padLeft(2, '0')})',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: c.text2))
              : _Link(resend, onTap: busy ? null : () => submit(widget.auth.resendCode)),
      mockHint: widget.auth.isMock ? t.mockCode : null,
    );
  }
}

class _PasswordStep extends StatefulWidget {
  const _PasswordStep({required this.auth, required this.hint});

  final AuthService auth;
  final String hint;

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> with _Submit {
  final _ctrl = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_ctrl.text.isEmpty) {
      setState(() => error = context.s.auth.passwordEmpty);
      return;
    }
    await submit(() => widget.auth.sendPassword(_ctrl.text));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final t = context.s.auth;
    return _Form(
      top: const _RoundIcon(Icons.lock_outline),
      title: t.passwordTitle,
      subtitle: t.passwordSubtitle,
      field: _Field(
        controller: _ctrl,
        enabled: !busy,
        autofocus: true,
        obscure: !_show,
        hint: t.passwordHint,
        onChanged: (_) {
          if (error != null) setState(() => error = null);
        },
        onSubmitted: (_) => _go(),
        suffix: IconButton(
          tooltip: _show ? t.hidePassword : t.showPassword,
          onPressed: () => setState(() => _show = !_show),
          icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: c.icon),
        ),
      ),
      fieldNote: widget.hint.isEmpty ? null : t.passwordHintNote(widget.hint),
      error: error,
      button: t.signIn,
      busy: busy,
      onButton: _go,
      below: _Link(t.otherNumber, onTap: busy ? null : widget.auth.editPhone),
      mockHint: widget.auth.isMock ? t.mockPassword : null,
    );
  }
}

/// Busy flag + error text (current language) for one form.
mixin _Submit<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  Future<void> submit(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = context.s.auth.unexpectedError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

// ---------------------------------------------------------------- building blocks

class _Form extends StatelessWidget {
  const _Form({
    required this.top,
    required this.title,
    required this.subtitle,
    required this.field,
    required this.button,
    required this.busy,
    required this.onButton,
    this.titleAction,
    this.fieldNote,
    this.error,
    this.below,
    this.mockHint,
  });

  final Widget top;
  final String title;
  final Widget? titleAction;
  final String subtitle;
  final Widget field;
  final String? fieldNote;
  final String? error;
  final String button;
  final bool busy;
  final VoidCallback onButton;
  final Widget? below;
  final String? mockHint;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: top),
        const SizedBox(height: 22),
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
        if (titleAction != null) ...[const SizedBox(height: 2), Center(child: titleAction)],
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: c.text2)),
        const SizedBox(height: 24),
        field,
        if (fieldNote != null) ...[
          const SizedBox(height: 6),
          Text(fieldNote!, style: TextStyle(fontSize: 13, color: c.text2)),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: TextStyle(fontSize: 13.5, color: c.danger)),
                ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: busy ? null : onButton,
            style: FilledButton.styleFrom(
              backgroundColor: c.accentStrong,
              foregroundColor: Colors.white,
              disabledBackgroundColor: c.accentStrong.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : Text(button),
          ),
        ),
        if (below != null) ...[const SizedBox(height: 16), Center(child: below)],
        if (mockHint != null) ...[const SizedBox(height: 22), _MockNote(mockHint!)],
        const SizedBox(height: 28),
        const _PrivacyNote(),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.onSubmitted,
    required this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.obscure = false,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
    this.suffix,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool autofocus;
  final bool obscure;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    OutlineInputBorder border(Color color, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: w));
    return TextField(
      controller: controller,
      // readOnly instead of enabled: a disabled field loses focus, so after a
      // wrong code the user could not type again without clicking.
      readOnly: !enabled,
      autofocus: autofocus,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      style: (style ?? const TextStyle(fontSize: 16)).copyWith(color: c.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.text2, letterSpacing: 0, fontWeight: FontWeight.w400, fontSize: 16),
        filled: true,
        fillColor: c.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffix,
        border: border(c.chipBorder),
        enabledBorder: border(c.chipBorder),
        disabledBorder: border(c.chipBorder),
        focusedBorder: border(c.accent, 2),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
      child: Icon(icon, size: 36, color: c.accentText),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, {required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: c.accentText,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FokusLogo(size: 76),
        const SizedBox(height: 28),
        SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6, color: c.accent)),
        const SizedBox(height: 16),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.text2)),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.message, required this.action, required this.onAction});

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _RoundIcon(icon)),
        const SizedBox(height: 22),
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.text)),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: c.text2)),
        const SizedBox(height: 24),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: c.accentStrong,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            child: Text(action),
          ),
        ),
      ],
    );
  }
}

class _MockNote extends StatelessWidget {
  const _MockNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 18, color: c.accentText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${context.s.auth.mockMode} $text',
              style: TextStyle(fontSize: 13, height: 1.35, color: c.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, size: 16, color: c.localFg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.s.auth.privacyNote,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.text2),
          ),
        ),
      ],
    );
  }
}

/// Keeps the phone field as `+998 90 123 45 67`.
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 15 ? digits.substring(0, 15) : digits;
    final text = formatPhone(capped);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
