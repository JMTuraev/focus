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
