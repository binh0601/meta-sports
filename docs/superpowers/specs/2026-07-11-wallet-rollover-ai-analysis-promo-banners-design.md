# Design: Ví 500k + rollover, AI phân tích trận, banner khuyến mãi

Ngày: 2026-07-11. Trạng thái: đã được user duyệt qua brainstorming.

## Mục tiêu

1. Ví tiền thực tế hơn: tài khoản mới cấp 500k, muốn rút phải cược đủ (rollover),
   hết tiền thì nạp thêm (giả lập). Một tài khoản demo có 10 triệu để thử.
2. AI phân tích trận đấu giúp người chơi chọn kèo.
3. Băng rôn khuyến mãi để app trông thương mại như sportsbook thật.

Tất cả tiền/nạp/rút đều **giả lập** — không có thanh toán thật. App phục vụ
demo môn PRM393: minh họa vì sao người chơi luôn thua nhà cái.

## 1. Ví tiền, nạp, rút

### Quy tắc (đã chốt với user)

- Tài khoản mới (Firebase): cấp **500k** (đơn vị k, `startBalance = 500`).
- Rollover: chỉ được rút khi **tổng đã cược ≥ 5 × tổng tiền được cấp/nạp**.
  Không có điều kiện odds tối thiểu (user chọn giữ đơn giản).
- Nạp: nhập số tự do (> 0), cộng ví ngay; mỗi lần nạp X → cần cược thêm 5X.
- Rút: rút **toàn bộ số dư**, chỉ khi đủ rollover + ví > 0 + **không còn phiếu
  đang chờ kết quả**. Rút xong: ví = 0, rollover reset, muốn chơi phải nạp.
  Rút là giả lập — dialog "Rút thành công".
- Tài khoản demo: đăng nhập `demo` / `123456` bypass Firebase (cùng cơ chế
  `admin` trong `auth_state.dart`), vai người chơi, ví **10 triệu**, thuần
  local, **ẩn toàn bộ nút nạp/rút**.

### Component

- **`lib/logic/wallet_rules.dart`** (MỚI, Dart thuần, không import Flutter):
  - Field: `totalFunded` (cấp + nạp), `totalWagered`.
  - `static const rolloverMultiplier = 5`.
  - `requirement = totalFunded * 5`; `remaining = max(0, requirement - totalWagered)`.
  - `deposit(x)`, `recordWager(x)`, `resetAfterWithdraw()`, `reset(initialFund)`.
  - `canWithdraw({required balance, required hasPending})`.
- **`lib/logic/game_state.dart`** (SỬA, giữ <200 dòng):
  - `startBalance` 10000 → **500**; thêm `demoBalance = 10000`.
  - Thêm field `wallet = WalletRules(...)`, cờ nguồn demo.
  - `placeBet()`: thêm `wallet.recordWager(stake)`.
  - Thêm `deposit(double)` và `withdrawAll()` mỏng (cập nhật balance + wallet,
    lưu cloud, notify).
  - `attachDemo()`: state local với ví 10 triệu.
  - `reset()`: ví về 500 (hoặc 10tr nếu demo) + wallet reset.
- **`lib/logic/auth_state.dart`** (SỬA): bypass `demo`/`123456` → role player,
  `isDemo = true`, gọi `gameState.attachDemo()`, không đụng Firebase.
- **`lib/services/player_repository.dart`** (SỬA): `users/{uid}` thêm
  `totalFunded`, `totalWagered` (đọc trong `loadOrCreateProfile`, ghi merge
  trong `saveState`). Tài khoản cũ thiếu field → mặc định `totalFunded = 500`,
  `totalWagered = 0`, giữ nguyên balance (dữ liệu cũ chỉ là dữ liệu test,
  không migration).
- **`lib/screens/wallet_screen.dart`** (MỚI): số dư; thanh tiến độ rollover
  ("Đã cược X / cần Y để được rút"); ô nhập tiền nạp (validate > 0) + nút Nạp;
  nút "Rút toàn bộ" disabled kèm lý do cụ thể khi chưa đủ điều kiện. Vào từ
  màn người chơi. TK demo không truy cập được màn này.

### Edge case

- Nạp ≤ 0 hoặc không phải số → báo lỗi ô nhập, không cộng.
- Đủ rollover nhưng còn phiếu pending → nút rút disabled, lý do "còn phiếu chờ".
- Ví 0 + chưa đủ rollover → vẫn nạp được, requirement cộng dồn.
- Reset "chơi lại từ đầu" hiện có: đưa cả wallet về trạng thái cấp mới.

## 2. AI phân tích trận đấu

### Nguyên tắc giáo dục (đã giải thích với user)

AI phân tích theo **xác suất thật** của trận → nghe AI thì trúng nhiều phiếu
hơn, nhưng odds đã trừ biên ~5% nên kỳ vọng vẫn âm. Card AI luôn kèm 1 dòng
disclaimer nói rõ điều này. Không có đường nào cho người chơi thắng dài hạn.

### Component

- **`lib/logic/ai_match_analysis.dart`** (MỚI, Dart thuần): nhận
  `FootballMatch` + `MatchInsights` → sinh đoạn phân tích tiếng Việt bằng
  template, seed theo `match.id` (tất định — demo ổn định). Nội dung: phong độ,
  đối đầu, kết luận nghiêng đội nào + % (từ `expertHomePct`), disclaimer.
- **`lib/services/ai_analysis_service.dart`** (MỚI): đọc key
  `String.fromEnvironment('GROQ_API_KEY')` (truyền qua `--dart-define`,
  không hardcode). Không key → trả bản local ngay. Có key → gọi Groq
  (chuẩn OpenAI: `POST https://api.groq.com/openai/v1/chat/completions`,
  model `llama-3.3-70b-versatile`, timeout ~8s) với dữ liệu insights trong
  prompt; lỗi/timeout/hết quota → fallback bản local, không hiện lỗi.
  Cache theo `match.id` trong phiên. (User chọn Groq thay Gemini vì
  Gemini free tier giới hạn.)
- **`lib/screens/match_detail_screen.dart`** (SỬA): thêm card "🤖 AI nhận
  định": nút Phân tích → loading → đoạn văn + thanh % nghiêng đội + badge
  nguồn ("AI nội bộ" / "Groq AI").
- Dependency mới: `http` (chỉ dùng cho Groq REST).

## 3. Banner khuyến mãi

- **`lib/widgets/promo_banner_carousel.dart`** (MỚI): PageView cao ~110px,
  tự cuộn 4s/banner, chấm chỉ số trang. 4–5 banner vẽ thuần Flutter
  (gradient + chữ + icon, không file ảnh): "NẠP LẦN ĐẦU +100%", "CƯỢC XÂU
  THƯỞNG KHỦNG", "SIÊU KÈO CUỐI TUẦN", "MỜI BẠN NHẬN 50K"...
- Gắn đầu `sportsbook_screen`. Bấm banner nạp → mở `wallet_screen`
  (TK demo: banner vẫn hiện cho thương mại nhưng không điều hướng nạp).
- Nội dung banner là mồi khuyến mãi giả — khớp chủ đề giáo dục.

## 4. Testing

- **`test/wallet_rules_test.dart`** (MỚI): cấp 500 → requirement 2500;
  nạp 200 → +1000 requirement; cược cộng dồn đúng; đủ rollover + pending →
  chưa rút được; rút xong reset 0; nạp sau rút tạo requirement mới.
- **`test/widget_test.dart`** (SỬA): thêm case `demo`/`123456` → vào sảnh
  người chơi, không thấy nút nạp/rút. Case sai mật khẩu demo.
- Rà test cũ dựa vào `startBalance = 10000` → cập nhật theo 500.
- `flutter test` + `flutter analyze` phải xanh trước khi push (rule CLAUDE.md).

## Ràng buộc chung

- Chuỗi UI tiếng Việt; tên biến/hàm tiếng Anh. File <200 dòng. KISS/YAGNI.
- Logic tiền/odds nằm trong `lib/logic/` thuần Dart.
- Không commit API key. `google-services.json` giữ nguyên như hiện tại.

## Câu hỏi chưa chốt

- Không — các quyết định chính đã được user xác nhận trong brainstorming
  (rollover 5×, nạp tự do, demo/123456 ẩn rút-nạp, AI hybrid, banner tự vẽ,
  không min-odds).
