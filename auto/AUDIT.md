# Focus chat va biznes auditi

Sana: 2026-yil 11-oktabr, Asia/Tashkent. Maqsad: Telegram kabi tanish chatni biznes vositalari bilan kuchaytirish va ixtiyoriy donat.

## Git va yetkazish

### 15-oktabr: xabar menyusi va lokal yangilash

Foydalanuvchi bergan skrinshotdagi menyuning xabar ustiga tushishi o‘rnatilgan ilovada ham tasdiqlandi. Yangi `message_menu.dart` haqiqiy bubble va history viewportini overlay koordinatalariga o‘tkazadi: joy bo‘lsa yon tomonda, tor oynada tepa/pastda ochadi va chat chegarasida ushlab turadi. Tanlangan bubble ajratiladi; bitta menyu ochiladi, chat/account almashishida yopiladi va eski rights javobi tashlanadi. SelectionArea menyusi bilan ustma-ust chiqish to‘xtatilgan. Ranglar mavjud palitradan, tarjimalar uch tilda.

Menyuga **Vazifa qilish** va **Eslatmaga** qo‘shildi. Aynan o‘ng bosilgan xabar olinadi; avval tanlangan/oxirgi xabar aralashmaydi. Telegram rights yuklanmasa ham lokal amallar mavjud. Hujjat satri shu menyuga ulanadi; fayl ochish/papkada ko‘rsatish/saqlash va Fayllarga qo‘shish saqlangan. Matnsiz media eslatmasi bo‘sh yozuvga aylanmaydi. Ma’lumot schema 8 va akkauntga tegishli bazada saqlanadi; Telegramga yuborish/read amali qo‘shilmagan.

**269/269 umumiy test o‘tdi**. Yangi menyu uchun 9 test: aynan bosilgan xabar, lokal task/note havolalari, offline rights, hujjat menyusi, kechikkan javob, Escape, offset overlay, uch tilda 420×560 tor oyna va chegaralar. Dastlabki regressiya sinovi mock hujjatda `file` null bo‘lsa Fayllarga bandi yo‘qolishini aniqladi; shart tuzatilib, butun suite qayta o‘tdi. Windows oynasida **5 integration ssenariysi o‘tdi**, jumladan menyudan haqiqiy vaqtinchalik SQLite bazaga task/note saqlash (driver +7 setup/teardown bilan, exit 0). User bazasida test task/note yaratilmagan.

Installer endi paketni oldindan nusxalab, papkalarni almashtiradi va oldingi EXE/DLL/assets nusxasini `Focus.previous-*` da saqlaydi. Xatoda papka qaytariladi; mavjud yorliq saqlanadi. `-SkipBuild` faqat muvaffaqiyatli oddiy, real-Telegram Release manifesti bilan ishlaydi; mock/test yoki tugallanmagan build rad etiladi. App support ma’lumotlari installer tomonidan o‘chirilmaydi.

**Foydalanuvchining aniq o‘rnatish/run ruxsati bilan bajarildi:** oddiy `lib/main.dart`, `USE_MOCK=false` Release yig‘ildi; secrets qiymatlari chiqarilmadi. Eski Focus odatiy Alt+F4 bilan yopildi. Support papkasining **774 fayli** lokal git-ignored `build/audit/upgrade-*/data` nusxasiga ko‘chirilib, har bir SHA-256 tekshirildi. Installer eski ilova papkasini saqlab, yangi buildni o‘rnatdi. O‘rnatilgan EXE, AOT `data/app.so` va TDLib SHA-256 qiymatlari yig‘ilgan bundle bilan bir xil. Yangi ilova ochilishidan oldin **774 asl faylning hammasi hash bo‘yicha o‘zgarmagani** yana tekshirildi.

Yangi ilova mavjud Telegram sessiyasini ochdi. Dastlab eski lokal ma’lumotlar egaligi oynasi chiqdi; agent import/alohida saqlash tugmalarini bosmadi. Keyingi tekshiruvda oyna yopilgan va akkaunt ochiq edi. Foydalanuvchining «qiziq emas» javobidan keyin qo‘shimcha import amali bajarilmadi. Asl baza, kalitlar va eski ilova nusxasi saqlangan. AllClubs/Xposter/Firebase deploy yoki ma’lumotlari bilan amal bajarilmagan.

### 15-oktabr: haqiqiy akkauntda yakuniy tekshiruv

Profil avatarining Windows accessibility daraxtida faqat rasm bo‘lib qolishi aniqlandi. Avatar endi tarjima qilingan nomi va tap amali bor tugma sifatida beriladi; sichqoncha orqali ochish ham saqlangan. Chat sarlavhasi va mijoz paneli testlari aynan semantics tap orqali galereyani ochadi. **13/13 profil testi qayta o‘tdi**, analyzer toza. Shu kod bilan oddiy real-Telegram Release qayta yig‘ilib o‘rnatildi. Ikkinchi almashtirishdan oldin **778 fayl** nusxasi hash bo‘yicha tekshirildi; o‘rnatilgan EXE va AOT yig‘ilgan bundle bilan bir xil.

Haqiqiy akkauntdagi tekshiruv **muvaffaqiyatli tugadi**: mavjud sessiya login kiritmasdan ochildi, 49 chat yuklandi. 9 ta ko‘rinadigan profil rasmi bor mijozda dastlabki ikki to‘liq rasm yuklanib haqiqiy dekoder bilan ochildi (birinchi rasm 640×640). Haqiqiy `ChatView` va `ProfilePhotoViewer` oynasida galereya ochilishi, **1→2→1** navigatsiya va Escape tekshirildi. Shu chatdagi xabarni o‘ng bosganda **Vazifa qilish / Eslatmaga** bandlari mavjudligi tasdiqlandi; ular jonli bazaga saqlash uchun bosilmadi.

Jonli tekshiruv git-ignored `build/audit/live_profile_probe.dart` orqali bajarildi: joriy native Debug host nusxasi va yangi Dart bundle, real `TdAuth`/`TdChatSource`, biznes ma’lumotlari uchun faqat xotiradagi bazalar. `openSession`, AccountStorage, settings, backup va notification xizmatlari ishga tushirilmadi. Xabar yuborish, o‘qilganlik belgisi, test vazifa/eslatma yoki legacy import bo‘lmadi. TDLib odatiy lokal keshiga rasmlarni yukladi. Chat nomlari, ID, rasmlar va kalitlar hisobotga kiritilmadi; qisqa natija `build/audit/live-profile-report.json`, driver exit **0**, `All tests passed`.

Computer Use accessibility holati yangilandi, lekin screenshot oqimi eski/oq kadrda qolgan; shu sabab qo‘lda vizual ko‘rish yakunlangan deb hisoblanmaydi. Jonli funksional tekshiruv yuqoridagi Windows integration orqali bajarildi. Bir martalik software-rendering urinishidan keyin oddiy ishga tushirishga qaytildi; doimiy rendering sozlamalari o‘zgartirilmadi. Asl legacy SQLite va mavjud kalit faylining SHA-256 qiymatlari birinchi nusxa bilan hamon bir xil (**2/2**); TDLib keshining o‘zgarishi yuklangan rasmlar uchun tabiiy. O‘rnatilgan odatiy Release sinovdan so‘ng qayta ochildi. Avvalgi bo‘limlardagi «o‘rnatilmadi/real akkaunt tekshirilmadi» yozuvlari o‘sha bosqichning tarixiy holatini bildiradi.

### 15-oktabr: profil rasmlari

Chat sarlavhasi va mijoz ma’lumot panelidagi avatar endi katta rasm oynasini ochadi. Ko‘rinadigan rasmlar tarixi, joriy personal/public fallback rasmi, sahifalash, oldingi/keyingi tugmalar va ←/→, 6× gacha kattalashtirish, Escape/× bilan yopish qo‘shildi. Rasmi yo‘q, tarmoq xatosi va qayta yuklash holatlari uch tilda bor. Tor oynada oynaning yopish tugmasi Windows title baridan pastda qoladi. Animatsiyali avatarlar hozir statik rasm sifatida ochiladi.

TDLib 1.8.67 sxemasi (`build/audit/td_api_1_8_67.tl`, workflow ref `3e04c757f9ee474db684baf94c433b28165c698d`) bo‘yicha foydalanuvchi rasmlari `getUserProfilePhotos`, guruh/kanal tarixi `searchChatMessages` + `searchMessagesFilterChatPhoto` orqali olinadi. Current personal/public photo to‘liq infodan olinib, history bilan takrorlanmaydi. Offset xom server natijalari bilan hisoblanadi, guruhda server cursori ishlatiladi. Faqat tanlangan to‘liq rasm yuklanadi; fayl holati akkauntning mavjud source keshidan olinadi. Chat/account almashishi oynani yopadi; disposed source kechikkan javobni tashlab yuboradi. `viewMessages` yoki typing/read amali qo‘shilmagan.

Sinovlar faqat sintetik auth/chat va yangi vaqtinchalik fayllarda. Mavjud support papkasi, TDLib login bazasi, schema 8, backup formati va o‘rnatilgan ilova o‘zgartirilmadi. Real Telegram akkauntida jonli profil rasmlari hali tekshirilmagan.

- Umumiy suite **260/260** o‘tdi; shundan yangi profil rasmlari bo‘yicha **13 test**. So‘ng sintetik PNG haqiqiy dekoder bilan alohida tasdiqlanib, profil testlari yana o‘tdi. Native dastlabki sinovda noto‘g‘ri PNG fixture aniqlangan va tuzatilgan; foydalanuvchi rasmiga tajriba qilinmagan.
- Yangi Windows Debug build va alohida oynadagi **4 integration ssenariysi o‘tdi**: A/B SQLite ajratilishi, reply/forward, profil rasmlarini ochish/navigatsiya/Escape va akkaunt almashishida yopish, Ctrl+F/qidiruv. Driver natijasi `All tests passed`, exit 0 (setup/teardown bilan +6). Windows SDK plugin ogohlantirishi avvalgidek chiqadi; Dart driver barcha natijalarni olgan.
- O‘rnatilgan Focus ochiq bo‘lgani uchun dastlabki test ishga tushmagan. Aynan vaqtinchalik bazali test targeti uchun alohida mutex va `Focus Tests` sarlavhasi qo‘shildi. Oddiy buildda `FOCUS_INTEGRATION_TEST_RUNNER=OFF` aniq beriladi; ishlab turgan ilovaning bitta nusxa himoyasi va data identity saqlangan. Foydalanuvchining Focus jarayoni yopilmagan/almashtirilmagan.
- Native sinov oldin/keyin support papkasidagi **774 faylning nisbiy yo‘llari, o‘lchamlari va o‘zgartirish vaqtlari aynan bir xil**. Metadata inventarlari faqat git-ignored `build/audit/profile-data-*.json` fayllarida; kontent yoki maxfiy qiymatlar chiqarilmagan.
- Oddiy `lib/main.dart` **Release build yig‘ildi**, mock rejimda va o‘rnatilmagan. CMake keshida test runner **OFF**; Release EXE ichida production mutex mavjud, test mutex mavjud emas. Yakuniy `flutter analyze --no-pub` va `git diff --check` toza. Sichqoncha g‘ildiragi bilan real transform kattalashishi ham tekshirilib, **13/13 profil testi qayta o‘tdi**.

Boshlang‘ich lokal main va origin/main bir xil ce12c96 commitda edi (oldinda/ortda 0/0). Ish codex/telegram-chat-audit branchida. Ushbu audit shu branchdagi kod commitiga kiradi; commit/push natijasi yakuniy chat xabarida tekshiriladi. Main ga merge va ilovani tarqatish bajarilmaydi.

Avvaldan o‘zgargan auto/LOG.md va auto/PARITY.md saqlandi, tahrirlanmadi va ushbu commitga kirmaydi. secrets.json Git’dan chiqarilgan; maxfiy qiymatlar chiqarilmadi.

## Topilgan va tuzatilgan muammolar

| Daraja | Boshlang‘ich muammo | Tayyor kod |
| --- | --- | --- |
| P1 | A akkauntdagi vazifalar, eslatmalar, qoralamalar, saqlangan elementlar va backup kaliti/sozlamasi B akkauntga ham umumiy bazadan ochilardi. Avtomatik backup eski ma’lumotni B ning Saved Messages’iga yuklashi mumkin edi. | TdAuth.openSession avval getMe bilan musbat Telegram ID oladi. Identifikatsiya xatosida umumiy bazaga qaytmaydi. AccountStorage baza va DPAPI backup kalitini accounts/<ID>/ papkasiga ajratadi. |
| P1 | Eski umumiy bazaning egasi yo‘q; uni keyingi kirgan akkauntga avtomatik tayinlash xavfli. | Ilova ma’lumotni ko‘rsatish va backupdan oldin “Shu akkauntga olish / Alohida saqlash” tanlovini beradi. Asl SQLite, JSON va kalit saqlanadi. Nusxa committed WAL ma’lumotlarini ham oladi. Import auto backupni o‘chiradi va egani belgilaydi. Uzilgan tanlov yoki shikastlangan JSON importidan keyin qayta urinish mumkin. |
| P1 | Kechikkan session/backup javobi va eski notification havolasi boshqa akkauntga ta’sir qilishi mumkin. | Eski session yopilishi va reminders bekor qilinishi kutiladi. Session avlodi va UI kaliti eski holatni rad etadi. Backup callback/taymerlari logoutdan keyin yangi ish boshlamaydi. Real notification account:<ID>: prefiksi bilan tekshiriladi; boshqa akkaunt va eski umumiy payload rad etiladi. |
| P1 | Chat almashtirish matnni boshqa chatga olib o‘tardi; kechikkan jo‘natish xatosi yangi qoralamani bosishi mumkin edi. | Per-chat matn/reply qoralamasi va draft versiyasi bilan himoya qo‘shildi. Tahrirlash oddiy qoralamani bosmaydi. |
| P1 | Fayl tanlash/dialog paytida chat almashsa, yangi chatga yuborilishi mumkin edi; caption xatoda yo‘qolardi. | Dialogdan keyin chat tekshiriladi. Boshlangan amal dastlabki chatda qoladi. Caption faqat muvaffaqiyatdan keyin va yangi matn bo‘lmasa tozalanadi. Qisman yuborilgan album avtomatik retry qilinmaydi. |
| P2 | TDLib workflow standarti master bo‘lib, keyingi DLL’da API o‘zgarishi mumkin edi. | Standart ref 3e04c757f9ee474db684baf94c433b28165c698d (1.8.67) bilan belgilandi. [Rasmiy td_api.tl](https://github.com/tdlib/td/blob/3e04c757f9ee474db684baf94c433b28165c698d/td/generate/scheme/td_api.tl) tekshirildi. Workflow ishga tushirilmadi. |

Mavzu, til va notification kabi qurilma sozlamalari umumiy qoladi. Akkaunt biznes ma’lumotlari alohida. Mock sessionlar xotirada.

## Reply, forward va qidiruv

- Xabar menyusidagi reply/forward getMessageProperties ruxsatlari bilan boshqariladi. Reply matn, document va albumda inputMessageReplyToMessage orqali yuboriladi.
- Reply qoralamasi chat va akkaunt bilan saqlanadi. Bekor qilish, chat almashish, restart va xatoda tiklash bor. Bubble’da muallif va asl matn/quote ko‘rinadi; yetishmagan original getMessage bilan olinadi. Previewni bosish asl xabarga o‘tadi.
- Forward oynasida yozish mumkin bo‘lgan chatlar qidiriladi, qabul qiluvchi tanlanadi va yuborish tasdiqlanadi. Muallif/caption saqlanadi (send_copy=false, remove_caption=false). Himoyalangan xabar cheklovini nusxalash bilan aylanib o‘tish yo‘q.
- Ctrl+F yoki sarlavhadagi qidiruv searchChatMessages bilan chat tarixidan qidiradi, faqat yuklangan xabarlardan emas. Natijalar next_from_message_id orqali sahifalanadi. So‘rov tez o‘zgarsa, eski javob ko‘rsatilmaydi; yo‘q natija, xato va retry holatlari bor.
- Natija/previewni bosish getChatHistory orqali target atrofidagi tarixni yuklaydi va xabarni ekranga joylashtiradi. Tarixdagi bo‘shliqlar yashirilmaydi. Eskirgan javob yangi o‘tishni bosmaydi. Pastga tugmasi oxirgi tarixga qaytaradi.
- Yuqori/pastki tugmalar qidiruv natijalarini tanlaydi; Escape qidiruvni yopadi. Tor oynada qidiruv va emoji paneli bir paytda joyni egallamaydi. Yangi matnlar o‘zbek/rus/ingliz tillarida.

Qoralamalar key_values jadvalidagi chatDraft:<chatId> va chatReplyDraft:<chatId> kalitlarida. Sxema **8** va **FOKUSBAK** formati saqlandi; snapshot qoralamalarni ham tiklaydi. Qoralamalar boshqa Telegram qurilmalariga sinxronlanmaydi. Enter yuboradi, Shift+Enter yangi qator qo‘shadi; IME tarkibidagi Enter yubormaydi.

## Ochiq audit masalalari

| Daraja | Qolgan ish |
| --- | --- |
| P1 | LocalMode online=false va read/typing bloklarini saqlaydi. [Telegram API Terms 1.4](https://core.telegram.org/api/terms) bilan zidlik ommaviy reliz oldidan hal qilinishi kerak. CLAUDE.md ning mavjud talabi bu topshiriqda o‘zgartirilmadi. |
| P1 | Kanallardagi rasmiy sponsored messages olish/ko‘rsatish mexanizmi yo‘q ([Terms 3.3](https://core.telegram.org/api/terms)). |
| P2 | Chat ro‘yxati start(pages: 3) bilan dastlabki uch 100 talik sahifani oladi; keyingi sahifa uchun UI yo‘q. Ko‘p mijozli akkaunt uchun to‘liq yuklash kerak. |
| P2 | Failed jo‘natishni qayta yuborish boshqaruvi va qisman yuborilgan album tafsilotlari yo‘q. |
| P2 | Real Telegram login/media/jo‘natish/notification sinovi tasdiqlanmagan; yangi Windows Debug/Release build va sintetik native test holati quyida. |

Telegram Desktop bilan tenglikka qolgan ishlar: ko‘p xabar tanlash/guruhli forward, reaksiyalar, link preview, clipboard rasmlari, mikrofon yozuvi, audio mini-player/tezlik/navbat, inline video va photo viewer navigatsiyasi. Reply/forward hozir bitta xabar uchun. Tashqi chat/topikdan yangi reply yaratish va quote matnini tanlash muharriri yo‘q; serverdan kelgan mavjud quote ko‘rsatiladi.

## Biznes va donat

To‘plamlar, javob kutilayotgan chatlar, xabardan vazifa/eslatma/uchrashuv, kanban, muddatli eslatmalar va tanlab saqlangan fayllar mavjud. Statistika yuklangan chatlar asosida; barcha mijozlarning to‘liq statistikasi deb talqin qilinmasin.

Donat oynasi va Payme/Click/Tirikchilik/HTTPS/karta konfiguratsiyasi mavjud. Donat ixtiyoriy, funksiyalarni ochmaydi. Lokal rekvizitlar/havolalar to‘ldirilmagan; real donat qabul qilish tayyor emas. To‘lov tasdig‘i/hisobi provayderda; reliz tavsifida monetizatsiya usuli ochiq ko‘rsatilishi kerak ([Terms 3.1–3.2](https://core.telegram.org/api/terms)).

## Sinov va ishlayotgan ilova holati

- Boshlang‘ich kod: analyzer toza, **196 test** o‘tgan.
- Yakuniy kod: flutter test --no-pub — **246 test o‘tdi** (boshlang‘ich kodga nisbatan **50 yangi test**). Flutter analyze --no-pub va git diff --check **toza**. Yakuniy test uslubi tuzatishidan keyin chat_protocol_test.dart dagi **8 test** yana o‘tdi; analyzer ham toza.
- Faqat sintetik lokal bazalar, mock UI va fake TDLib ishlatildi. A/B/restart, DPAPI kalitlari, committed WAL, explicit import/retry, eski notification, tez session almashishi, kechikkan backup, qoralama/snapshot, reply text/document/album, protected forward, server qidiruvi/cursor, kechikkan tarix va uch tilda tor oyna qamrab olindi.
- Oldingi offline DLL tekshiruvi **1.8.67** qaytargan. Real Telegram login/xabar jo‘natish qilinmadi.
- Dastlabki to‘liq Windows build Visual Studio aniqlanmagani sababli tugamagan. Quyidagi dastlabki ishga tushirish sinovi mavjud native host bilan bajarildi; keyingi «Windows build tuzatishi va native sinov» bo‘limida yangi Debug/Release native build natijalari berilgan. Real media ijrosi hali tasdiqlanmagan.
- **Prod:** ilova o‘rnatilmadi/tarqatilmadi. Foydalanuvchi bazasi va Telegram ma’lumotlari o‘zgartirilmadi. AllClubs/Xposter/Rezone/Dood loyihalariga murojaat qilinmadi.

### Windows oynasida amaliy sinov — 11-oktabr

Joriy `b2f56ab` Dart kodi `flutter build bundle --debug --target-platform windows-x64 --dart-define=USE_MOCK=true` orqali qayta yig‘ildi. 4-oktabrdagi mavjud Debug native host nusxasi alohida `build/audit/ui_run/Debug` papkasiga olindi va yangi kernel/assets bilan ishga tushirildi. Kernel nusxasi va yangi bundle SHA-256 qiymatlari bir xil; mavjud `flutter_windows.dll` ham joriy Flutter 3.38.9 dvigateli bilan bir xil. Bu yangi Dart kodining Windows oynasidagi sinovi; yangi EXE/plugin kompilyatsiyasi yoki release build sinovi emas.

`build/audit/ui_smoke_main.dart` lokal harnessi asl `FokusApp` va `AuthGate` orqali `MockAuth(loggedIn: true)`, `Settings.inMemory` va xotiradagi chat/biznes bazasini ishlatadi. Kirish oynasi avtomatlashtirilmadi, TDLib yuklanmadi, Telegramga xabar yuborilmadi. Sinov runtime’i odatiy o‘rnatilgan ilova yoki foydalanuvchi ma’lumotlarini almashtirmaydi.

Computer Use bilan Windows oynasida tekshirildi:

- Xabarni o‘ng bosish menyusi, reply preview va yuborilgan javobdagi asl xabar/muallif.
- Dilshod chatidagi matn/reply qoralamasi Madina chatiga o‘tmaydi; qaytishda ikkalasi tiklanadi.
- Forward oynasida chatni tanlash va yuborish; Madina chatida Dilshod muallifligi va asl matn ko‘rinadi.
- Sarlavhadagi chat qidiruvi, natijalar hisoblagichi, natijaga o‘tish/highlight va yuqori/pastki natija tugmalari (1/3 → 2/3 → 1/3).
- Tungi rejim; 420×560 oynada chat ro‘yxatidan chatga o‘tish, qidiruv, natijaga o‘tish va composer joylashuvi. Render overflow ko‘rinmadi.
- Qayta boshlangan toza sinovda Enter bilan mock xabar muvaffaqiyatli yuborildi.

Cheklovlar: Computer Use matn joylash/klaviatura kombinatsiyalari Flutter `HardwareKeyboard`’ga noto‘g‘ri physical-key hodisalarini yubordi; Ctrl+F native avtomatizatsiyada tasdiqlanmadi. Ctrl+F va Shift+Enter/IME xatti-harakati widget testlarida qamrab olingan. Dastlabki taskbar badge `SetOverlayIcon` chaqiruvi ushlangan PlatformException (-1) berdi; Windows badge/notification bu sinov bilan tasdiqlanmaydi. Real akkaunt A/B, TDLib jo‘natish/qidiruv, media va yangi to‘liq native build hali alohida sinov talab qiladi.

Oyna sinovidan keyin `chat_drafts_test.dart` va `chat_interactions_test.dart` qayta ishga tushirildi: **22/22 test o‘tdi**, jumladan Ctrl+F, Enter, Shift+Enter, IME va tor oynaning uch tili. Ishlayotgan mock oyna 1200×780 o‘lchamga qaytarildi.

## Qaytarish va keyingi ishlar

### Windows build tuzatishi va native sinov

Avvalgi cheklov sababi: MSVC 14.44.35207, ATL va Windows SDK 10.0.26100.0 mavjud, lekin Visual Studio discovery bo‘sh natija bergan; o‘rnatilgan CMake 3.31.6-msvc6 `--version` chaqiruvida ham access violation bilan tugagan. Flutter/VS tizim fayllari almashtirilmadi. `tool/build_windows.ps1` loyiha ichidagi tekshirilgan Kitware CMake 3.31.6 nusxasi, aniq VS yo‘li va `version=17.14.37411.7` bilan [portable instance](https://cmake.org/cmake/help/latest/variable/CMAKE_GENERATOR_INSTANCE.html) usulidan foydalanadi. Rasmiy arxiv SHA-256 bilan tekshiriladi. `TEMP`/`TMP` faqat build jarayonida loyiha papkasiga o‘tadi va keyin tiklanadi. Standart `flutter doctor`/VS registratsiyasi hali bo‘sh natija berishi mumkin; ushbu loyiha build skripti bilan yig‘iladi.

- **Yangi native Debug build:** EXE, barcha C++ plaginlar va Dart kodi to‘liq yig‘ildi. Eski EXE’ga yangi kernel qo‘yish usuli ishlatilmadi.
- **Yangi Release build:** oddiy `lib/main.dart`, `USE_MOCK=true`; `build/windows-portable/x64/runner/Release/focus.exe` va AOT `data/app.so` tayyor. Test targeti Release artifactiga kiritilmagan.
- Build skripti Windows PowerShell 5.1 bilan ham Release bundle yig‘di. Release ichidagi `tdjson.dll` lokal, tarmoqqa ulanmagan tekshiruvda **1.8.67** qaytardi.
- Lokal installer kelajakda shu build skriptidan foydalanadi. Installer bu topshiriqda ishga tushirilmadi; `%LOCALAPPDATA%/Programs/Focus` dagi ilova almashtirilmadi.
- **Windows oynasida uchta avtomatik integration ssenariysi o‘tdi:** A→B→A→B akkaunt almashishi (haqiqiy vaqtinchalik SQLite bazalari, vazifalar, matn/reply qoralamalari va qayta ochishda tiklash); multiline reply/Shift+Enter/Enter va muallifli forward; Ctrl+F, qidiruv, 1/2→2/2→1/2 navigatsiya va Escape.
- Native test qidiruv natijalariga o‘tilgach Escape panelni yopmasligini aniqladi. Search input fokusi tiklandi; chat bo‘ylab Escape qidiruvni yopib, yozish maydoniga qaytadi. Composerda Escape qidiruv ochiq bo‘lsa reply qoralamasini bekor qilmaydi. Alohida regression widget testi qo‘shildi va o‘tdi.
- Integration harness `TdAuth` va `Settings.load` ni chaqirmaydi, Windows notification xizmatini boshlamaydi. Auth/chat source sintetik; SQLite/account storage haqiqiy. Sinov papkasi har safar yangi, foydalanuvchi bazasi bilan aralashtirilmaydi; yopilish tugashi kutiladi. Windows SDK integration_test native plagini yo‘qligi haqidagi ogohlantirishni chiqardi, ammo Dart driver barcha natijalarni olib, muvaffaqiyatli tugadi.
- **Ma’lumot yaxlitligi:** foydalanuvchi support papkasidagi 770 faylning oldin/keyin inventarlari aynan bir xil. Fayl o‘lchami va vaqtlar, biznes SQLite/JSON, settings va kalitlarning SHA-256 qiymatlari o‘zgarmagan. Inventarlar faqat git-ignored `build/audit/` da; maxfiy qiymatlar yoki foydalanuvchi kontenti hisobotga chiqarilmagan.
- **Yakuniy tekshiruv:** `flutter test --no-pub --concurrency=1` — **247/247 test o‘tdi**; `flutter analyze --no-pub` — muammo yo‘q. Native integration sinovida uchta ssenariy o‘tdi (setup/teardown bilan driver hisoblagichi +5). `git diff --check` toza.
- C: diskidagi bo‘sh joy test kompilyatsiyasiga yetmadi; keyingi sinovlar loyiha ichidagi D: vaqtinchalik papkasi bilan bajarildi. Parallel test/analyzer urinishida xotira yetishmasligi kuzatildi; yakuniy suite ketma-ket, `--concurrency=1` bilan muvaffaqiyatli bajarildi.

Real Telegram akkauntlari bilan kirish/jo‘natish va foydalanuvchining legacy bazasini import qilish sinovi bajarilmadi. Bu topshiriqda mavjud ma’lumotlarni test uchun ishlatish yoki production o‘zgarish bo‘lmadi. Schema 8 va FOKUSBAK formati saqlangan.

Asl umumiy baza va backup kaliti saqlanadi. Yangi akkaunt papkalarini o‘chirmang yoki aralashtirmang. Kodni oldingi versiyaga qaytarish root umumiy bazani yana ishlatadi va akkaunt ajratilishini yo‘qotadi. Yangi akkaunt ma’lumotini eski umumiy bazaga avtomatik aralashtirish kerak emas. Schema/backup formati o‘zgarmagan; boshqa qurilmada backupdan tiklash parol bilan explicit amal bo‘lib qoladi.

Keyingi ustuvorlik: alohida Telegram test akkauntida qo‘lda tekshirish; lokal rejim/Telegram qoidalari; sponsored messages va to‘liq chat ro‘yxati; ko‘p xabar/reactions/audio; donat rekvizitlari. auto/LOG.md va auto/PARITY.md dagi foydalanuvchi o‘zgarishlariga tegilmasin.
