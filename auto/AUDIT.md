# Focus chat va biznes auditi

Sana: 2026-yil 11-oktabr, Asia/Tashkent. Maqsad: Telegram kabi tanish chatni biznes vositalari bilan kuchaytirish va ixtiyoriy donat.

## Git va yetkazish

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
| P2 | Windows build va real login/media/jo‘natish/notification sinovi tasdiqlanmagan. |

Telegram Desktop bilan tenglikka qolgan ishlar: ko‘p xabar tanlash/guruhli forward, reaksiyalar, link preview, clipboard rasmlari, mikrofon yozuvi, audio mini-player/tezlik/navbat, inline video va photo viewer navigatsiyasi. Reply/forward hozir bitta xabar uchun. Tashqi chat/topikdan yangi reply yaratish va quote matnini tanlash muharriri yo‘q; serverdan kelgan mavjud quote ko‘rsatiladi.

## Biznes va donat

To‘plamlar, javob kutilayotgan chatlar, xabardan vazifa/eslatma/uchrashuv, kanban, muddatli eslatmalar va tanlab saqlangan fayllar mavjud. Statistika yuklangan chatlar asosida; barcha mijozlarning to‘liq statistikasi deb talqin qilinmasin.

Donat oynasi va Payme/Click/Tirikchilik/HTTPS/karta konfiguratsiyasi mavjud. Donat ixtiyoriy, funksiyalarni ochmaydi. Lokal rekvizitlar/havolalar to‘ldirilmagan; real donat qabul qilish tayyor emas. To‘lov tasdig‘i/hisobi provayderda; reliz tavsifida monetizatsiya usuli ochiq ko‘rsatilishi kerak ([Terms 3.1–3.2](https://core.telegram.org/api/terms)).

## Sinov va ishlayotgan ilova holati

- Boshlang‘ich kod: analyzer toza, **196 test** o‘tgan.
- Yakuniy kod: flutter test --no-pub — **246 test o‘tdi** (boshlang‘ich kodga nisbatan **50 yangi test**). Flutter analyze --no-pub va git diff --check **toza**. Yakuniy test uslubi tuzatishidan keyin chat_protocol_test.dart dagi **8 test** yana o‘tdi; analyzer ham toza.
- Faqat sintetik lokal bazalar, mock UI va fake TDLib ishlatildi. A/B/restart, DPAPI kalitlari, committed WAL, explicit import/retry, eski notification, tez session almashishi, kechikkan backup, qoralama/snapshot, reply text/document/album, protected forward, server qidiruvi/cursor, kechikkan tarix va uch tilda tor oyna qamrab olindi.
- Oldingi offline DLL tekshiruvi **1.8.67** qaytargan. Real Telegram login/xabar jo‘natish qilinmadi.
- Windows mock build mos Visual Studio C++ toolchain yo‘qligi sababli tugamagan. Native kompilyatsiya va real media ijrosi tasdiqlanmagan.
- **Prod:** ilova o‘rnatilmadi/tarqatilmadi. Foydalanuvchi bazasi va Telegram ma’lumotlari o‘zgartirilmadi. AllClubs/Xposter/Rezone/Dood loyihalariga murojaat qilinmadi.

## Qaytarish va keyingi ishlar

Asl umumiy baza va backup kaliti saqlanadi. Yangi akkaunt papkalarini o‘chirmang yoki aralashtirmang. Kodni oldingi versiyaga qaytarish root umumiy bazani yana ishlatadi va akkaunt ajratilishini yo‘qotadi. Yangi akkaunt ma’lumotini eski umumiy bazaga avtomatik aralashtirish kerak emas. Schema/backup formati o‘zgarmagan; boshqa qurilmada backupdan tiklash parol bilan explicit amal bo‘lib qoladi.

Keyingi ustuvorlik: Windows build muhiti va test akkauntda qo‘lda tekshirish; lokal rejim/Telegram qoidalari; sponsored messages va to‘liq chat ro‘yxati; ko‘p xabar/reactions/audio; donat rekvizitlari. auto/LOG.md va auto/PARITY.md dagi foydalanuvchi o‘zgarishlariga tegilmasin.
