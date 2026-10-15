# Focus

Windows uchun norasmiy Telegram klienti: chatlar TDLib orqali ishlaydi, to‘plamlar, vazifalar, kalendar, eslatmalar va saqlangan fayllar lokal bazada turadi. Standart ishga tushirish sinov ma’lumotlarini ishlatadi; haqiqiy Telegram uchun `USE_MOCK=false` kerak.

2026-yil 11-oktabrdagi [audit va navbatdagi ishlar](auto/AUDIT.md). Akkauntga tegishli lokal ma’lumotlar, reply/forward va chat tarixidagi qidiruv qo‘shilgan. Chat qismi Telegram Desktop bilan hali to‘liq teng emas. Donat oynasi mavjud; to‘lov rekvizitlari build sozlamalarida beriladi.

## 1. Loyihani ishga tushirish

```powershell
cd D:\focus
powershell -ExecutionPolicy Bypass -File tool\setup_windows.ps1
flutter pub get
flutter run -d windows
```

## Windows build: mavjud MSVC aniqlanmasa

VS 2022 C++/ATL va Windows SDK fayllari bor, lekin `flutter build windows` ularni aniqlamayotgan kompyuterda loyiha skriptidan foydalaning:

```powershell
flutter pub get
./tool/build_windows.ps1 -Mode Release
```

Skript [CMake’ning portable Visual Studio instance usuli](https://cmake.org/cmake/help/latest/variable/CMAKE_GENERATOR_INSTANCE.html) bilan MSVC yo‘li va versiyasini ko‘rsatadi. CMake 3.31.6 [Kitware rasmiy arxividan](https://github.com/Kitware/CMake/releases/tag/v3.31.6) olinadi va SHA-256 tekshiriladi. Kesh va vaqtinchalik fayllar `build/` ichida; kompyuterdagi Flutter/Visual Studio fayllari o‘zgartirilmaydi. Natija: `build/windows-portable/x64/runner/Release/focus.exe`. Standart build mock rejimda. Skript ilovani o‘rnatmaydi va foydalanuvchi bazasiga murojaat qilmaydi.

Haqiqiy Telegram buildini alohida tayyorlash uchun `-RealTelegram -DefineFile secrets.json` qo‘shing. Uni ishga tushirish odatdagi foydalanuvchi ma’lumotlarini ochadi; buni sintetik test bilan aralashtirmang.

Windows oynasida avtomatik sinov (haqiqiy akkaunt yoki Telegramga ulanmaydi):

```powershell
./tool/build_windows.ps1 -Target integration_test/desktop_chat_test.dart
$env:TEMP = "$PWD/build/toolchain/temp"
$env:TMP = $env:TEMP
flutter drive -d windows --no-pub --driver test_driver/desktop.dart --target integration_test/desktop_chat_test.dart --use-application-binary build/windows-portable/x64/runner/Debug/focus.exe --dart-define=USE_MOCK=true
```

Bu test EXEsi vaqtinchalik alohida SQLite bazalarda A→B→A almashish, qoralama/reply, forward, Ctrl+F, qidiruv natijalari va profil rasmlarini tekshiradi. Aynan shu test targeti alohida mutex va `Focus Tests` oynasidan foydalanadi: o‘rnatilgan Focus ochiq qolishi mumkin. Test targetini foydalanuvchiga tarqatmang; oddiy ilova uchun skriptni `-Target lib/main.dart -Mode Release` bilan qayta bajaring. Oddiy buildda test identifikatori o‘chiriladi va bitta nusxa himoyasi saqlanadi. C: diskida joy kam bo‘lsa, lokal testlarda ham `TEMP`/`TMP` ni shu `build/toolchain/temp` papkasiga yo‘naltiring; xotira cheklangan muhitda `flutter test --concurrency=1` ishlating.

## 2. Telegram kalitlari

`secrets.example.json` dan nusxa olib, `secrets.json` deb saqlang va my.telegram.org'dagi `api_id` / `api_hash` ni yozing. Bu fayl `.gitignore` da — GitHub'ga tushmaydi.

```powershell
flutter run -d windows --dart-define-from-file=secrets.json
```

## 3. TDLib (tdjson.dll)

1. GitHub’dagi loyiha uchun Actions bo‘limini oching.
2. Actions → **TDLib (Windows x64)** → **Run workflow**. Standart TDLib manbasi **1.8.67**, commit `3e04c757f9ee474db684baf94c433b28165c698d`. Boshqa versiyani tanlashdan oldin JSON API mosligini tekshiring.
3. Tayyor bo'lgach `tdlib-windows-x64` artifaktini yuklab oling va ichidagi 4 ta DLL'ni `tdlib\` papkasiga qo'ying.
4. Tekshirish:
   ```powershell
   dart run tool\td_check.dart tdlib\tdjson.dll
   ```
   `TDLib ishlayapti. Versiya: 1.8.x` chiqishi kerak.

## Profil rasmlari

Chat sarlavhasidagi yoki ma’lumot panelidagi avatarni bosing. Katta rasm ochiladi; yon tugmalar yoki ←/→ bilan tarix bo‘ylab yuring, sichqoncha g‘ildiragi bilan kattalashtiring. Escape yoki × oynani yopadi. Telegram ruxsat bergan shaxsiy profil rasmlari va guruh/kanal rasmlari tarixi ko‘rsatiladi; maxfiylik bilan yashirilgan rasmlar olinmaydi. Akkaunt yoki chat almashganda rasm oynasi yopiladi. Animatsiyali avatarlarning statik rasmi ko‘rsatiladi.

Xabarni o‘ng bosing: reply/forward va fayl amallari bilan birga **Vazifa qilish** va **Eslatmaga** chiqadi. Aynan bosilgan xabar, chat havolasi va matni lokal bazaga saqlanadi; Telegramga xabar yuborilmaydi. Menyu bo‘sh joy bo‘lsa xabar yonida, tor oynada tepa/pastida ochiladi va chat chegarasida qoladi.

## Lokal yangilash

`tool/install_local.ps1` haqiqiy Telegram Release buildini o‘rnatadi. Avval Focusni yoping. Eski ilova `Programs/Focus.previous-*` papkasida qaytarish uchun saqlanadi; app support bazasi yoki login fayllari o‘chirilmaydi. Nusxalash tugagach papka almashtiriladi. `-SkipBuild` faqat `tool/build_windows.ps1 -Mode Release -RealTelegram -DefineFile secrets.json` bilan muvaffaqiyatli yig‘ilgan oddiy build uchun: installer `focus-build.json` orqali mock/test/tugallanmagan buildni rad etadi. Eski umumiy biznes bazasini akkauntga import qilish ilovadagi alohida egalik tanlovi orqali bajariladi; original fayllar saqlanadi.

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
  setup_windows.ps1      DLL'larni focus.exe yoniga nusxalash qoidasi
.github/workflows/tdlib-windows.yml
```

## Lokal rejim qoidalari

- `online` opsiyasi doim `false`.
- `viewMessages` va `sendChatAction` chaqirilmaydi — telefoningizda xabarlar o'qilmagan bo'lib qoladi.
- Bu xatti-harakatlar [Telegram API qoidalarining 1.4-bandi](https://core.telegram.org/api/terms) bilan mos emas. Ommaviy chiqarishdan oldin loyiha egasi bilan qoidalarni va normal Telegram statuslari bilan ishlashni kelishish kerak.

Chat qoralamalari lokal SQLite bazada har bir chat uchun alohida saqlanadi; Telegram va boshqa qurilmalarga sinxronlanmaydi. Tahrirlashni bekor qilish avvalgi qoralamani qaytaradi. Enter yuboradi, Shift+Enter yangi qator qo‘shadi.

Xabarning o‘ng tugma menyusidan **Javob berish** yoki **Forward** tanlanadi. Reply qoralamasi chat va akkaunt bilan saqlanadi; asl xabar ko‘rinishini bosish uning tarixdagi joyiga olib boradi. Forward oynasida qabul qiluvchi tanlanib, yuborish tasdiqlanadi; muallif va caption saqlanadi, himoyalangan xabarlar uchun bu amal taklif qilinmaydi.

Chat sarlavhasidagi qidiruv tugmasi yoki **Ctrl+F** chat tarixidan qidiradi. Natijalar sahifalanadi; yuqori/pastki tugmalar natijalar orasida yuradi, natijani bosish xabarga o‘tadi. **Escape** qidiruvni yopadi, tarixdagi pastga tugmasi oxirgi xabarlarga qaytaradi.

## Akkaunt ma’lumotlari

Haqiqiy login Telegram foydalanuvchi ID’sini aniqlagandan keyin lokal bazani ochadi. Har bir akkauntning vazifalari, kalendari, eslatmalari, to‘plamlari, saqlangan fayl havolalari, qoralamalari va backup sozlamalari support papkasidagi `accounts/<Telegram-ID>/fokus.sqlite` da saqlanadi. Backup kaliti ham shu akkauntning papkasida. Mavzu va til kabi qurilma sozlamalari umumiy qoladi.

Eski umumiy baza mavjud bo‘lsa, birinchi ochishda uni **shu akkauntga olish** yoki **alohida saqlash** tanlovi chiqadi. Ma’lumotlarni faqat tegishli akkauntga oling. Asl baza, JSON va backup kaliti saqlanadi; ko‘chirish avtomatik backupni o‘chiradi. Tanlov uzilib qolsa, keyingi ochishda qayta taklif qilinadi. Akkauntdan chiqish uning rejalashtirilgan eslatmalarini bekor qiladi; eski akkaunt bildirishnomasi yangi akkauntdagi vazifani ochmaydi.

## Login

Sinov rejimi (standart, Telegram’ga ulanmaydi): istalgan raqam, istalgan 5 xonali kod, istalgan parol.

Haqiqiy Telegram bilan:

```powershell
flutter run -d windows --dart-define-from-file=secrets.json --dart-define=USE_MOCK=false
```

TDLib bazasi Windows DPAPI bilan himoyalangan tasodifiy kalit orqali shifrlanadi.

## Kompyuterga o‘rnatish

Release build qilib, `%LOCALAPPDATA%\Programs\Focus` ga o‘rnatadi va ish stoliga "Focus" yorlig‘ini qo‘yadi. Login va lokal ma’lumotlar saqlanib qoladi. Avval Focus’ni yoping.

```powershell
powershell -ExecutionPolicy Bypass -File tool\install_local.ps1
```

Ikonka `tool\make_icon.py` bilan logotipdan yasaladi.

## Keyingi qadam

Vazifalar, kalendar, eslatmalar, SQLite, shifrlangan zaxira, donat, fayllar va statistika kodda mavjud. Keyingi ustuvorliklar: Telegram qoidalariga moslik, to‘liq chat ro‘yxatini yuklash, ko‘p xabarni tanlash, reaksiyalar va audio boshqaruvi. Aniq holat [auditda](auto/AUDIT.md), kichik vazifalar `auto/ROADMAP.md` va `auto/PARITY.md` da yuritiladi.
