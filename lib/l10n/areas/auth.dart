import '../l10n.dart' show enPlural, ruPlural;

/// Login: phone, code, 2FA password, TDLib errors.
class AuthStrings {
  AuthStrings({
    required this.loading,
    required this.connecting,
    required this.signingIn,
    required this.loggingOut,
    required this.unsupportedTitle,
    required this.failedTitle,
    required this.otherNumber,
    required this.next,
    required this.mockMode,
    required this.privacyNote,
    required this.unexpectedError,
    required this.phoneTitle,
    required this.phoneSubtitle,
    required this.phoneTooShort,
    required this.mockPhone,
    required this.changeNumber,
    required this.codeEmpty,
    required this.codeViaTelegram,
    required this.codeSmsWord,
    required this.codeViaSms,
    required this.codeViaCall,
    required this.codeViaFlashCall,
    required this.codeViaFragment,
    required this.codeViaEmail,
    required this.codeSent,
    required this.resendViaSms,
    required this.resendViaCall,
    required this.resend,
    required this.codeHint,
    required this.codeWordHint,
    required this.mockCode,
    required this.passwordTitle,
    required this.passwordSubtitle,
    required this.passwordHint,
    required this.passwordEmpty,
    required this.showPassword,
    required this.hidePassword,
    required this.passwordHintNote,
    required this.signIn,
    required this.mockPassword,
    required this.noApiKeys,
    required this.tdlibLoadFailed,
    required this.dbKeyFailed,
    required this.noAccount,
    required this.emailRequired,
    required this.unknownMethod,
    required this.notConnected,
    required this.errTimeout,
    required this.errFloodWait,
    required this.errPhoneInvalid,
    required this.errPhoneBanned,
    required this.errPhoneFlood,
    required this.errCodeInvalid,
    required this.errCodeExpired,
    required this.errPasswordInvalid,
    required this.errNoResendMethod,
    required this.errApiKeysInvalid,
    required this.errAuthRestart,
    required this.errDbKeyMismatch,
    required this.errTelegram,
  });

  // Busy and notice screens
  /// Mock start-up.
  final String loading;
  final String connecting;
  final String signingIn;
  final String loggingOut;
  final String unsupportedTitle;
  final String failedTitle;

  /// Back to the phone step (unsupported notice, password step).
  final String otherNumber;

  // Shared by the forms
  /// Main button of the phone and code steps.
  final String next;

  /// Prefix of the mock hint box.
  final String mockMode;
  final String privacyNote;
  final String Function(Object error) unexpectedError;

  // Phone step
  final String phoneTitle;
  final String phoneSubtitle;

  /// Shown before sending when the number has fewer than 9 digits.
  final String phoneTooShort;
  final String mockPhone;

  // Code step
  final String changeNumber;
  final String codeEmpty;
  final String codeViaTelegram;

  /// The "code" is a word or phrase from an SMS.
  final String codeSmsWord;
  final String codeViaSms;
  final String codeViaCall;

  /// Flash call / missed call: the code is the end of the caller's number.
  final String codeViaFlashCall;
  final String codeViaFragment;
  final String codeViaEmail;
  final String codeSent;
  final String resendViaSms;
  final String resendViaCall;
  final String resend;

  /// Field hints.
  final String codeHint;
  final String codeWordHint;
  final String mockCode;

  // Password step
  final String passwordTitle;
  final String passwordSubtitle;

  /// Field hint.
  final String passwordHint;
  final String passwordEmpty;
  final String showPassword;
  final String hidePassword;

  /// The user's own 2FA password hint.
  final String Function(String hint) passwordHintNote;
  final String signIn;
  final String mockPassword;

  // TDLib start-up and unsupported steps
  final String noApiKeys;
  final String tdlibLoadFailed;
  final String dbKeyFailed;

  /// The number has no Telegram account (sign-up is not supported).
  final String noAccount;
  final String emailRequired;
  final String unknownMethod;
  final String notConnected;

  // TDLib errors (authErrorText)
  final String errTimeout;

  /// FLOOD_WAIT: seconds to wait (0 when unknown).
  final String Function(int seconds) errFloodWait;
  final String errPhoneInvalid;
  final String errPhoneBanned;
  final String errPhoneFlood;
  final String errCodeInvalid;
  final String errCodeExpired;
  final String errPasswordInvalid;
  final String errNoResendMethod;
  final String errApiKeysInvalid;
  final String errAuthRestart;
  final String errDbKeyMismatch;

  /// Unknown TDLib error with its raw message.
  final String Function(String message) errTelegram;
}

final authUz = AuthStrings(
  loading: 'Yuklanmoqda…',
  connecting: 'Telegram’ga ulanmoqda…',
  signingIn: 'Kirilmoqda…',
  loggingOut: 'Akkauntdan chiqilmoqda…',
  unsupportedTitle: 'Bu usul hali qo‘llab-quvvatlanmaydi',
  failedTitle: 'Telegram’ga ulanib bo‘lmadi',
  otherNumber: 'Boshqa raqam bilan kirish',
  next: 'Davom etish',
  mockMode: 'Sinov rejimi: Telegram’ga ulanmaydi.',
  privacyNote: 'Kod va parol faqat Telegram serverlariga yuboriladi. Focus’ning o‘z serveri yo‘q, '
      'xabarlaringiz o‘qilgan deb belgilanmaydi.',
  unexpectedError: (e) => 'Kutilmagan xatolik: $e',
  phoneTitle: 'Telefon raqamingiz',
  phoneSubtitle: 'Mamlakat kodini tekshiring va Telegram’dagi telefon raqamingizni kiriting.',
  phoneTooShort: 'Telefon raqamini mamlakat kodi bilan to‘liq kiriting.',
  mockPhone: 'Istalgan raqam ishlaydi.',
  changeNumber: 'Raqamni o‘zgartirish',
  codeEmpty: 'Kodni kiriting.',
  codeViaTelegram: 'Kodni boshqa qurilmangizdagi Telegram ilovasiga yubordik.',
  codeSmsWord: 'SMS’dagi so‘z yoki iborani kiriting.',
  codeViaSms: 'Kodni SMS orqali yubordik.',
  codeViaCall: 'Sizga qo‘ng‘iroq qilinadi va kod aytib beriladi.',
  codeViaFlashCall: 'Sizga qo‘ng‘iroq qilinadi. Qo‘ng‘iroq qilgan raqamning oxirgi raqamlarini kiriting.',
  codeViaFragment: 'Kodni fragment.com’dagi hisobingizga yubordik.',
  codeViaEmail: 'Kodni emailingizga yubordik.',
  codeSent: 'Tasdiqlash kodini yubordik.',
  resendViaSms: 'Kodni SMS orqali yuborish',
  resendViaCall: 'Kodni qo‘ng‘iroq orqali olish',
  resend: 'Kodni qayta yuborish',
  codeHint: 'Kod',
  codeWordHint: 'SMS’dagi so‘z',
  mockCode: 'Istalgan 5 xonali kod ishlaydi, 00000 esa xato beradi.',
  passwordTitle: 'Ikki bosqichli tekshiruv',
  passwordSubtitle: 'Akkauntingiz qo‘shimcha parol bilan himoyalangan. Telegram’dagi bulut parolingizni kiriting.',
  passwordHint: 'Parol',
  passwordEmpty: 'Parolni kiriting.',
  showPassword: 'Parolni ko‘rsatish',
  hidePassword: 'Parolni yashirish',
  passwordHintNote: (h) => 'Maslahat: $h',
  signIn: 'Kirish',
  mockPassword: 'Istalgan parol ishlaydi, «xato» esa xato beradi.',
  noApiKeys: 'Telegram API kalitlari berilmagan. secrets.json’ni to‘ldiring va ilovani '
      '--dart-define-from-file=secrets.json bilan ishga tushiring.',
  tdlibLoadFailed: 'TDLib (tdjson.dll) yuklanmadi. tdlib\\ papkasidagi DLL’lar fokus.exe yonida ekanini tekshiring.',
  dbKeyFailed: 'TDLib bazasining kaliti ochilmadi. Ehtimol, papka boshqa Windows foydalanuvchisidan ko‘chirilgan. '
      'Ilova ma’lumotlari ichidagi tdlib papkasini o‘chirib, qayta kiring.',
  noAccount: 'Bu raqamda Telegram akkaunti yo‘q. Avval rasmiy Telegram ilovasida ro‘yxatdan o‘ting, '
      'keyin Focus orqali kiring.',
  emailRequired: 'Telegram bu kirish uchun email tasdiqlashni so‘rayapti. Bu imkoniyat Focus’da hali yo‘q. '
      'Avval rasmiy Telegram ilovasida emailni tasdiqlang, keyin qayta urinib ko‘ring.',
  unknownMethod: 'Telegram kutilmagan tasdiqlash usulini so‘rayapti. Rasmiy Telegram ilovasi orqali kirib ko‘ring.',
  notConnected: 'Telegram’ga ulanish hali tayyor emas. Bir oz kuting.',
  errTimeout: 'Telegram javob bermadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.',
  errFloodWait: (s) {
    final when = s >= 120 ? '${(s / 60).ceil()} daqiqadan' : (s > 0 ? '$s soniyadan' : 'birozdan');
    return 'Juda ko‘p urinish bo‘ldi. $when keyin qayta urinib ko‘ring.';
  },
  errPhoneInvalid: 'Telefon raqami noto‘g‘ri. Mamlakat kodi bilan to‘liq kiriting.',
  errPhoneBanned: 'Bu raqam Telegram tomonidan bloklangan.',
  errPhoneFlood: 'Bu raqam uchun juda ko‘p kod so‘raldi. Keyinroq urinib ko‘ring.',
  errCodeInvalid: 'Kod noto‘g‘ri. Qaytadan tekshirib kiriting.',
  errCodeExpired: 'Kodning muddati o‘tgan. Yangi kod so‘rang.',
  errPasswordInvalid: 'Parol noto‘g‘ri.',
  errNoResendMethod: 'Kodni qayta yuborishning boshqa usuli qolmadi.',
  errApiKeysInvalid: 'Telegram API kalitlari (api_id / api_hash) noto‘g‘ri. secrets.json’ni tekshiring.',
  errAuthRestart: 'Kirish jarayoni qayta boshlandi. Raqamni yana kiriting.',
  errDbKeyMismatch:
      'TDLib bazasini ochib bo‘lmadi (kalit mos emas). Ilova ma’lumotlari ichidagi tdlib papkasini o‘chirib, qayta kiring.',
  errTelegram: (m) => 'Telegram xatosi: $m',
);

final authRu = AuthStrings(
  loading: 'Загрузка…',
  connecting: 'Подключение к Telegram…',
  signingIn: 'Вход…',
  loggingOut: 'Выход из аккаунта…',
  unsupportedTitle: 'Этот способ пока не поддерживается',
  failedTitle: 'Не удалось подключиться к Telegram',
  otherNumber: 'Войти с другим номером',
  next: 'Далее',
  mockMode: 'Тестовый режим: без подключения к Telegram.',
  privacyNote: 'Код и пароль отправляются только на серверы Telegram. У Focus нет своего сервера, '
      'а ваши сообщения не отмечаются прочитанными.',
  unexpectedError: (e) => 'Непредвиденная ошибка: $e',
  phoneTitle: 'Ваш номер телефона',
  phoneSubtitle: 'Проверьте код страны и введите номер телефона, привязанный к Telegram.',
  phoneTooShort: 'Введите полный номер телефона с кодом страны.',
  mockPhone: 'Подойдёт любой номер.',
  changeNumber: 'Изменить номер',
  codeEmpty: 'Введите код.',
  codeViaTelegram: 'Мы отправили код в приложение Telegram на другом вашем устройстве.',
  codeSmsWord: 'Введите слово или фразу из SMS.',
  codeViaSms: 'Мы отправили код по SMS.',
  codeViaCall: 'Мы позвоним вам и продиктуем код.',
  codeViaFlashCall: 'Вам поступит звонок. Введите последние цифры номера, с которого звонили.',
  codeViaFragment: 'Мы отправили код в ваш аккаунт на fragment.com.',
  codeViaEmail: 'Мы отправили код на вашу почту.',
  codeSent: 'Мы отправили код подтверждения.',
  resendViaSms: 'Отправить код по SMS',
  resendViaCall: 'Получить код звонком',
  resend: 'Отправить код повторно',
  codeHint: 'Код',
  codeWordHint: 'Слово из SMS',
  mockCode: 'Подойдёт любой 5-значный код, а 00000 вызовет ошибку.',
  passwordTitle: 'Двухэтапная аутентификация',
  passwordSubtitle: 'Ваш аккаунт защищён дополнительным паролем. Введите облачный пароль Telegram.',
  passwordHint: 'Пароль',
  passwordEmpty: 'Введите пароль.',
  showPassword: 'Показать пароль',
  hidePassword: 'Скрыть пароль',
  passwordHintNote: (h) => 'Подсказка: $h',
  signIn: 'Войти',
  mockPassword: 'Подойдёт любой пароль, а «xato» вызовет ошибку.',
  noApiKeys: 'Не заданы ключи Telegram API. Заполните secrets.json и запустите приложение '
      'с --dart-define-from-file=secrets.json.',
  tdlibLoadFailed:
      'Не удалось загрузить TDLib (tdjson.dll). Проверьте, что DLL из папки tdlib\\ лежат рядом с fokus.exe.',
  dbKeyFailed:
      'Не удалось открыть ключ базы данных TDLib. Возможно, папка скопирована от другого пользователя Windows. '
      'Удалите папку tdlib в данных приложения и войдите снова.',
  noAccount: 'С этим номером нет аккаунта Telegram. Сначала зарегистрируйтесь в официальном приложении Telegram, '
      'затем войдите через Focus.',
  emailRequired: 'Для этого входа Telegram просит подтвердить email. В Focus такой возможности пока нет. '
      'Сначала подтвердите email в официальном приложении Telegram, затем попробуйте снова.',
  unknownMethod:
      'Telegram запрашивает неизвестный способ подтверждения. Попробуйте войти через официальное приложение Telegram.',
  notConnected: 'Подключение к Telegram ещё не готово. Подождите немного.',
  errTimeout: 'Telegram не отвечает. Проверьте подключение к интернету и попробуйте снова.',
  errFloodWait: (s) {
    final m = (s / 60).ceil();
    final when = s >= 120
        ? 'через $m ${ruPlural(m, 'минуту', 'минуты', 'минут')}'
        : (s > 0 ? 'через $s ${ruPlural(s, 'секунду', 'секунды', 'секунд')}' : 'чуть позже');
    return 'Слишком много попыток. Попробуйте снова $when.';
  },
  errPhoneInvalid: 'Неверный номер телефона. Введите полный номер с кодом страны.',
  errPhoneBanned: 'Этот номер заблокирован в Telegram.',
  errPhoneFlood: 'Для этого номера запрошено слишком много кодов. Попробуйте позже.',
  errCodeInvalid: 'Неверный код. Проверьте и введите его снова.',
  errCodeExpired: 'Срок действия кода истёк. Запросите новый код.',
  errPasswordInvalid: 'Неверный пароль.',
  errNoResendMethod: 'Других способов отправить код повторно не осталось.',
  errApiKeysInvalid: 'Неверные ключи Telegram API (api_id / api_hash). Проверьте secrets.json.',
  errAuthRestart: 'Вход начался заново. Введите номер ещё раз.',
  errDbKeyMismatch:
      'Не удалось открыть базу TDLib (ключ не подходит). Удалите папку tdlib в данных приложения и войдите снова.',
  errTelegram: (m) => 'Ошибка Telegram: $m',
);

final authEn = AuthStrings(
  loading: 'Loading…',
  connecting: 'Connecting to Telegram…',
  signingIn: 'Logging in…',
  loggingOut: 'Logging out…',
  unsupportedTitle: 'This method is not supported yet',
  failedTitle: 'Could not connect to Telegram',
  otherNumber: 'Log in with another number',
  next: 'Next',
  mockMode: 'Test mode: not connected to Telegram.',
  privacyNote: 'The code and password are sent only to Telegram servers. Focus has no server of its own, '
      'and your messages are never marked as read.',
  unexpectedError: (e) => 'Unexpected error: $e',
  phoneTitle: 'Your phone number',
  phoneSubtitle: 'Please confirm your country code and enter the phone number of your Telegram account.',
  phoneTooShort: 'Enter the full phone number with the country code.',
  mockPhone: 'Any number works.',
  changeNumber: 'Change number',
  codeEmpty: 'Enter the code.',
  codeViaTelegram: 'We’ve sent the code to the Telegram app on your other device.',
  codeSmsWord: 'Enter the word or phrase from the SMS.',
  codeViaSms: 'We’ve sent you a code via SMS.',
  codeViaCall: 'We will call you and dictate the code.',
  codeViaFlashCall: 'You will receive a call. Enter the last digits of the number that called you.',
  codeViaFragment: 'We’ve sent the code to your account on fragment.com.',
  codeViaEmail: 'We’ve sent the code to your email.',
  codeSent: 'We’ve sent you a verification code.',
  resendViaSms: 'Send the code via SMS',
  resendViaCall: 'Get the code via a call',
  resend: 'Resend code',
  codeHint: 'Code',
  codeWordHint: 'Word from the SMS',
  mockCode: 'Any 5-digit code works; 00000 gives an error.',
  passwordTitle: 'Two-step verification',
  passwordSubtitle: 'Your account is protected with an additional password. Enter your Telegram cloud password.',
  passwordHint: 'Password',
  passwordEmpty: 'Enter your password.',
  showPassword: 'Show password',
  hidePassword: 'Hide password',
  passwordHintNote: (h) => 'Hint: $h',
  signIn: 'Log in',
  mockPassword: 'Any password works; “xato” gives an error.',
  noApiKeys: 'Telegram API keys are missing. Fill in secrets.json and run the app '
      'with --dart-define-from-file=secrets.json.',
  tdlibLoadFailed:
      'Could not load TDLib (tdjson.dll). Check that the DLLs from the tdlib\\ folder are next to fokus.exe.',
  dbKeyFailed: 'Could not open the TDLib database key. The folder may have been copied from another Windows user. '
      'Delete the tdlib folder in the app data and log in again.',
  noAccount: 'There is no Telegram account with this number. Sign up in the official Telegram app first, '
      'then log in with Focus.',
  emailRequired: 'Telegram asks to confirm an email for this login. Focus does not support this yet. '
      'Confirm the email in the official Telegram app first, then try again.',
  unknownMethod: 'Telegram asks for an unknown verification method. Try logging in with the official Telegram app.',
  notConnected: 'The connection to Telegram is not ready yet. Please wait a moment.',
  errTimeout: 'Telegram did not respond. Check your internet connection and try again.',
  errFloodWait: (s) {
    final m = (s / 60).ceil();
    final when = s >= 120
        ? 'in $m ${enPlural(m, 'minute', 'minutes')}'
        : (s > 0 ? 'in $s ${enPlural(s, 'second', 'seconds')}' : 'a bit later');
    return 'Too many attempts. Please try again $when.';
  },
  errPhoneInvalid: 'Invalid phone number. Enter the full number with the country code.',
  errPhoneBanned: 'This phone number is banned by Telegram.',
  errPhoneFlood: 'Too many codes were requested for this number. Please try again later.',
  errCodeInvalid: 'Invalid code. Please check it and try again.',
  errCodeExpired: 'The code has expired. Please request a new one.',
  errPasswordInvalid: 'Invalid password.',
  errNoResendMethod: 'There are no other ways left to resend the code.',
  errApiKeysInvalid: 'Invalid Telegram API keys (api_id / api_hash). Check secrets.json.',
  errAuthRestart: 'Login was restarted. Please enter your number again.',
  errDbKeyMismatch:
      'Could not open the TDLib database (the key does not match). Delete the tdlib folder in the app data and log in again.',
  errTelegram: (m) => 'Telegram error: $m',
);
