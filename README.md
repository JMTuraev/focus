# Fokus — 0-bosqich skeleti

Windows uchun lokal ishlaydigan desktop klient. Hozircha soxta ma'lumot bilan ishlaydi (UI-first), TDLib qatlami tayyor, lekin UI'ga hali ulanmagan.

## 1. Loyihani ishga tushirish

```powershell
cd fokus
flutter create --platforms=windows --project-name fokus .   # windows\ papkasini yaratadi, lib\ ga tegmaydi
powershell -ExecutionPolicy Bypass -File tool\setup_windows.ps1
flutter pub get
flutter run -d windows
```

## 2. Telegram kalitlari

`secrets.example.json` dan nusxa olib, `secrets.json` deb saqlang va my.telegram.org'dagi `api_id` / `api_hash` ni yozing. Bu fayl `.gitignore` da — GitHub'ga tushmaydi.

```powershell
flutter run -d windows --dart-define-from-file=secrets.json
```

## 3. TDLib (tdjson.dll)

1. Loyihani **private** GitHub repoga yuklang.
2. Actions → **TDLib (Windows x64)** → **Run workflow** (taxminan 40–60 daqiqa).
3. Tayyor bo'lgach `tdlib-windows-x64` artifaktini yuklab oling va ichidagi 4 ta DLL'ni `tdlib\` papkasiga qo'ying.
4. Tekshirish:
   ```powershell
   dart run tool\td_check.dart tdlib\tdjson.dll
   ```
   `TDLib ishlayapti. Versiya: 1.8.x` chiqishi kerak.

## Tuzilma

```
lib/
  main.dart              oyna (1440×900, o'z sarlavha qatori)
  theme.dart             ranglar (yorug‘ va tungi palitra)
  config.dart            api_id/api_hash (build vaqtida)
  auth/                  login: AuthService, MockAuth (sinov rejimi)
  data/                  modellar, ChatSource, soxta ma’lumot, lokal holat (to‘plamlar)
  state/app_state.dart   UI holati (filtrlar, to'plamlar, yuborish)
  state/settings.dart    sozlamalar (mavzu rejimi)
  ui/                    sarlavha, chap panel, chatlar ekrani
  ui/layout.dart         keng / o‘rtacha / tor joylashuv chegaralari
  ui/login/             login ekrani: telefon → kod → 2FA parol
  tdlib/
    td_json.dart         tdjson.dll FFI
    td_client.dart       so'rov/javob + update oqimi (alohida isolate)
    td_auth.dart         login oqimi (TdAuth) + LocalMode qoidalari
    db_key.dart          TDLib bazasi kaliti (Windows DPAPI)
    td_chats.dart        chatlar va xabarlar TDLib update’laridan (TdChatSource)
tool/
  td_check.dart          DLL tekshiruvi
  setup_windows.ps1      DLL'larni fokus.exe yoniga nusxalash qoidasi
.github/workflows/tdlib-windows.yml
```

## Lokal rejim qoidalari

- `online` opsiyasi doim `false`.
- `viewMessages` va `sendChatAction` chaqirilmaydi — telefoningizda xabarlar o'qilmagan bo'lib qoladi.
- Cheklov: javob yozsangiz, Telegram chatni o'qilgan deb hisoblaydi.

## Login

Sinov rejimi (standart, Telegram’ga ulanmaydi): istalgan raqam, istalgan 5 xonali kod, istalgan parol.

Haqiqiy Telegram bilan:

```powershell
flutter run -d windows --dart-define-from-file=secrets.json --dart-define=USE_MOCK=false
```

TDLib bazasi Windows DPAPI bilan himoyalangan tasodifiy kalit orqali shifrlanadi.

## Keyingi qadam (1-bosqich davomi)

Chatlar ro‘yxati va xabarlarni TDLib’dan olish, to‘plamlar va filtrlarni haqiqiy chatlarga ulash.
