# house_edge_demo

App Flutter demo môn PRM393 — "Toán học nhà cái".

## 📥 Tải app (APK) — không cần cài Flutter

Muốn cài thử trên điện thoại Android mà không clone/build?

👉 **[Tải APK mới nhất tại trang Releases](https://github.com/binh0601/meta-sports/releases/latest)**

Mở link trên điện thoại → tải file `MegaSports.apk` → cài đặt (nếu máy hỏi thì
cho phép "Cài từ nguồn không xác định").

> APK được GitHub Actions **tự build và đăng lên Releases** mỗi khi đẩy một tag
> phiên bản (vd `v1.0.0`) — xem `.github/workflows/release-apk.yml`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

### Phân tích AI (tùy chọn)

Enable AI match analysis via Groq:
```bash
flutter run --dart-define=GROQ_API_KEY=<your-groq-api-key>
```
Without the key, the app runs normally and uses fallback local analysis.

### Tỷ số trực tiếp (tùy chọn)

Màn "Trực tiếp" (icon TV trên sảnh) hiện tỷ số bóng đá thật qua API-Football:
```bash
flutter run --dart-define=FOOTBALL_API_KEY=<your-api-sports-key>
```
Không có key thì màn này chạy chế độ demo (một trận giả tự chạy phút + sự kiện).
Chỉ để xem — không đặt cược trên trận thật.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Ghi cong hinh anh

- **action_worldcup.jpg**: [Germany players celebrate winning the 2014 FIFA World Cup.jpg](https://commons.wikimedia.org/wiki/File:Germany_players_celebrate_winning_the_2014_FIFA_World_Cup.jpg) by Agência Brasil, licensed under [CC BY 3.0 BR](https://creativecommons.org/licenses/by/3.0/br/)
- **action_stadium_flare.jpg**: [Bengalische Feuer, Maccabi Haifa Fans im EM-Stadion Wals-Siezenheim.jpg](https://commons.wikimedia.org/wiki/File:Bengalische_Feuer,_Maccabi_Haifa_Fans_im_EM-Stadion_Wals-Siezenheim.jpg), licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)
