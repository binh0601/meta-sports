# CLAUDE.md

Hướng dẫn cho Claude Code (và các AI tool khác) khi làm việc trong repo này.

## Tổng quan project

App Flutter demo môn PRM393: "Toán học nhà cái — vì sao người chơi luôn thua".
Mô phỏng sportsbook (kèo bóng đá, overround, parlay, martingale) với 2 vai trò:
người chơi và nhà cái (admin).

## Cấu trúc

```
lib/
├── main.dart          # Entry point, HouseEdgeApp
├── logic/             # Logic thuần (không phụ thuộc UI): betting_math,
│                      #   football_market, game_state, auth_state
├── screens/           # Mỗi màn hình 1 file (login, sportsbook, admin...)
├── services/          # Firebase (auth, firestore, messaging), notifications
├── widgets/           # Widget tái sử dụng (bet slip, brand crest...)
└── theme/             # Màu sắc thương hiệu
test/                  # Unit test cho logic + widget test cho luồng đăng nhập
```

## Lệnh thường dùng

```bash
flutter pub get                # Cài dependencies sau khi clone/pull
flutter run                    # Chạy app (chọn emulator/device)
flutter test                   # Chạy toàn bộ test — PHẢI PASS trước khi push
flutter analyze                # Kiểm tra lỗi phân tích tĩnh
flutter build apk --debug      # Build APK debug
```

**Lưu ý khi chạy test trên Windows:** chạy cả file (`flutter test test/widget_test.dart`),
đừng chạy từng test theo tên (`--plain-name`) vì tên test có dấu cách sẽ crash flutter tools.

## Firebase

- `android/app/google-services.json` đã có trong repo — Firebase tự kích hoạt khi build.
- App vẫn build và chạy được ở **chế độ local** nếu thiếu file này (xem
  `android/app/build.gradle.kts` và `lib/services/firebase_bootstrap.dart`).
- Tài khoản test bypass Firebase: `admin` / `123456` → vào dashboard nhà cái.
- `applicationId` là `com.megasports.demo` (đã đăng ký trên Firebase Console) —
  **không đổi** nếu không cập nhật Firebase Console.

## Quy tắc code

- Logic tính toán (odds, payout, house edge) đặt trong `lib/logic/`, viết thuần Dart,
  không import Flutter — để unit test được.
- Mỗi màn hình một file trong `lib/screens/`; widget dùng lại ≥2 nơi thì tách ra `lib/widgets/`.
- Giữ file dưới ~200 dòng; file phình to thì tách module.
- Chuỗi hiển thị UI viết **tiếng Việt**; tên biến/hàm/class viết tiếng Anh.
- Nguyên tắc: KISS, YAGNI — không thêm abstraction/config không cần thiết.
- Sửa logic trong `lib/logic/` thì phải thêm/cập nhật test tương ứng trong `test/`.

## Git

- Commit theo conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`.
- Chạy `flutter test` pass hết rồi mới push. Không skip/xóa test để cho build xanh.
- **Không commit:** `.claude/`, `android/local.properties`, keystore (`*.jks`, `key.properties`),
  file build output — đã có trong `.gitignore`, đừng force add.
- Làm việc nhóm: tạo branch riêng theo tính năng (`feat/ten-tinh-nang`), mở PR vào `main`.
