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

- `android/app/google-services.json` **KHÔNG có trong repo** (repo public) —
  xin file từ trưởng nhóm (binh0601) qua chat nhóm rồi đặt vào `android/app/`.
  Có file thì Firebase tự kích hoạt khi build.
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

## Git Flow (bắt buộc với cả người và AI tool)

Bản đầy đủ cho thành viên nhóm: `docs/git-workflow.md` (checklist trước khi
code, đặt tên branch, quy trình PR). Sửa quy tắc ở một file thì cập nhật cả hai.

**Nguyên tắc:** `main` luôn ổn định — build được, `flutter test` pass. **Cấm push
thẳng lên `main`**; mọi thay đổi đi qua branch + Pull Request.

### Quy trình làm một tính năng / sửa lỗi

1. Cập nhật main rồi tạo branch từ đó:
   ```bash
   git checkout main && git pull
   git checkout -b feat/ten-tinh-nang    # hoặc fix/..., docs/..., refactor/...
   ```
2. Code + commit trên branch đó. Commit nhỏ, tập trung, theo conventional
   commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
3. Trước khi push: `flutter analyze` sạch và `flutter test` pass hết.
   Không skip/xóa test để cho build xanh.
4. Push branch, mở PR vào `main`. Mô tả PR ghi rõ: làm gì, test thế nào.
5. Ít nhất 1 người khác review và approve rồi mới merge. Merge kiểu
   **Squash and merge** cho lịch sử main gọn. Merge xong xóa branch.
6. Branch bị tụt so với main → `git pull origin main` vào branch của mình
   và tự xử lý conflict trước khi nhờ review.

### Đặt tên branch

- `feat/wallet-rollover`, `fix/login-crash`, `docs/update-readme`...
- Chữ thường, nối bằng `-`, mô tả được nội dung, tiếng Anh.

### Cấm

- Force-push lên `main` (branch của mình thì được nếu chưa ai review).
- Commit: `.claude/`, `android/local.properties`, keystore (`*.jks`,
  `key.properties`), API key (Groq/Firebase secret), file build output.
- Commit code đang hỏng ("WIP không compile") lên branch chung.
