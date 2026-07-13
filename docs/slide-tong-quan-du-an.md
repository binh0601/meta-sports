# Toán học nhà cái — vì sao người chơi luôn thua
### App Flutter demo · PRM393

> Tài liệu tổng quan để dựng slide thuyết trình. Mỗi mục `##` = 1 slide (hoặc 1 cụm slide).

---

## Slide 1 — Mở đầu

**Tên đề tài:** Toán học nhà cái — vì sao người chơi luôn thua.

**Sản phẩm:** App Flutter mô phỏng một sportsbook (nhà cái cá cược bóng đá), dùng để
minh hoạ *bằng con số và trải nghiệm thực tế* rằng người chơi thua không phải vì
"đen", mà vì **toán học đã cài sẵn phần thắng cho nhà cái**.

**Thông điệp cốt lõi:** Nhà cái không cần gian lận. Chỉ cần một biên lợi thế nhỏ
(~5%) lặp lại đủ nhiều lần, người chơi *chắc chắn* thua về dài hạn.

---

## Slide 2 — Vấn đề & Mục tiêu

**Vấn đề:** Người chơi tin mình "soi kèo giỏi" sẽ thắng. Thực tế bị che mất phần
toán học nền tảng.

**Mục tiêu app:**
- Trực quan hoá các khái niệm: overround, hold, kỳ vọng (EV), luật số lớn.
- Cho người dùng *tự chơi* để cảm nhận thua dần theo thời gian.
- Đứng ở **2 vai**: người chơi (thấy ví cạn) và nhà cái/admin (thấy lãi tăng).

---

## Slide 3 — Hai vai trò trong app

| Vai trò | Trải nghiệm |
|---------|-------------|
| **Người chơi** | Được cấp 500k, đặt kèo bóng đá, xem ví vơi dần |
| **Nhà cái (admin)** | Dashboard theo dõi sổ sách, lãi cộng dồn, biên giữ lại |

Tài khoản demo bypass Firebase: `admin` / `123456` → vào dashboard nhà cái.

---

## Slide 4 — Kiến trúc & Công nghệ

**Nền tảng:** Flutter (Dart), Firebase (Auth / Firestore / Messaging — tuỳ chọn),
phân tích AI qua Groq (tuỳ chọn, có fallback local).

**Cấu trúc code — tách logic khỏi UI để test thuần Dart:**

```
lib/
├── logic/     # Toán thuần: betting_math, football_market,
│              #   handicap_settlement, wallet_rules, game_state...
├── screens/   # Mỗi màn hình 1 file (login, sportsbook, admin...)
├── services/  # Firebase, AI, notifications, player repository
├── widgets/   # Widget tái sử dụng (bet slip, match card, hero banner...)
└── theme/     # Màu thương hiệu
test/          # Unit test cho logic + widget test luồng đăng nhập
```

**Nguyên tắc:** logic tính toán không import Flutter → unit test được; file < 200 dòng; KISS/YAGNI/DRY.

---

## Slide 5 — Overround: nhà cái ăn ngay từ tỷ lệ kèo

Odds được định giá = xác suất thật × 0.95 → tổng xác suất ngầm > 100%.

- **Xác suất ngầm** một cửa = `1 / odds`
- **Overround** = tổng xác suất ngầm mọi cửa − 100%
- **Hold** (biên trên doanh thu) = `overround / (1 + overround)`

**Ví dụ chuẩn của tài liệu:** odds ~1.90 cho cả 2 cửa → overround ≈ **5,26%**.
Đây là "thuế" nhà cái thu bất kể ai thắng.

---

## Slide 6 — Kỳ vọng mỗi ván (EV) luôn âm

Cược 100k, odds 1.90, xác suất thắng thật p = 50%:

```
EV = p · stake · (odds − 1) − (1 − p) · stake
   = 0.5 · 100 · 0.9 − 0.5 · 100 = 45 − 50 = −5k / ván
```

→ Mỗi ván trung bình mất **5k**. Người chơi không cảm nhận được vì bị che bởi may rủi ngắn hạn.

---

## Slide 7 — Cuộc đua: biên nhà cái vs. may rủi

Hai lực đối nghịch theo số ván `n`:

- **Biên nhà cái (kéo thắng chắc chắn):** `5 · n` — tăng tuyến tính.
- **Dao động may rủi (độ lệch chuẩn):** `95 · √n` — tăng theo căn.

**Điểm giao:** `5n = 95√n → n = 361 ván.`

Trước 361 ván, may rủi còn che được; sau đó **biên nhà cái luôn thắng may rủi**.
Chơi càng lâu, càng chắc thua.

---

## Slide 8 — Luật số lớn: bao nhiêu người còn lời?

Xấp xỉ tỷ lệ người chơi còn dương sau `n` ván:

```
winnersShare(n) = P(Z > √n / 19)
```

Càng nhiều ván, `√n/19` càng lớn → phần người còn lời co về gần 0.
Không phải "vài người xui" — mà **gần như tất cả** đều về âm.

---

## Slide 9 — Bẫy Martingale (gấp thếp)

Chiến thuật "thua thì gấp đôi để gỡ". Với odds 1.90:

```
martingaleNet(k) = 100 − 10 · 2^k
```

Từ lần thua thứ 4 trở đi → **net âm**. Chuỗi thua ngắn cũng đủ cháy tài khoản
(`martingaleCycle`: gấp đôi đến khi thắng *hoặc* hết tiền → thường hết tiền trước).

---

## Slide 10 — Bẫy Parlay (kèo xâu)

Ghép nhiều kèo để "ăn to". Mỗi kèo nhà cái giữ ~5% giá trị:

```
parlayMargin(k) = 1 − 0.95^k
```

Ghép càng nhiều cửa (k), biên nhà cái càng phình. Phần thưởng lớn đánh đổi bằng
xác suất thắng tụt dốc — EV càng âm nặng.

---

## Slide 11 — Kèo chấp Châu Á (Asian Handicap)

App cham kèo chấp thật (`handicap_settlement.dart`):
- Line nguyên/nửa: thắng / hoà vốn / thua.
- **Line 1/4 (quarter):** tách cược làm đôi ở 2 line → trạng thái *thắng nửa /
  thua nửa* (halfWin, halfLose, push).

Điểm giáo dục: kèo chấp làm kết quả "gần thắng" nhưng vẫn nghiêng về nhà cái.

---

## Slide 12 — "Soi kèo" cũng vô ích

`match_insights.dart` sinh dữ liệu soi kèo (phong độ 5 trận, đối đầu, %
chuyên gia, % cộng đồng) — nhưng **tất cả phản ánh đúng xác suất thật**.

→ Dù soi chuẩn đến mấy, người chơi vẫn không vượt được biên 5% của nhà cái.
Cảm giác "có thông tin" chỉ khiến chơi nhiều hơn.

---

## Slide 13 — Luật rollover: giữ chân người chơi

`wallet_rules.dart` mô phỏng điều khoản bonus thật:

- Tiền được cấp/nạp phải **cược đủ ít nhất 1 lần** trước khi rút.
- Còn phiếu chờ kết quả → chưa rút được.
- Rút hết → ví về 0, muốn chơi tiếp phải nạp mới.

→ Người chơi buộc phải cho tiền chạy qua house edge nhiều vòng → thua thêm.

---

## Slide 14 — Trải nghiệm & UI

- Splash động, typography kiểu gaming (RussoOne, ChakraPetch).
- Sportsbook: chuyển giải (World Cup...), match card có hiệu ứng, hero banner Ken Burns.
- Hiệu ứng đặt cược: coin burst, gold rain, shimmer.
- Card phân tích AI (Groq) với hiệu ứng gõ chữ; không có key → fallback local.
- Ví, lịch sử cược, hồ sơ người chơi; dashboard nhà cái xem sổ sách & lãi.

---

## Slide 15 — Kết luận

**Nhà cái luôn thắng vì toán học, không vì gian lận:**
1. Overround ~5% ăn ngay trên tỷ lệ kèo.
2. EV mỗi ván âm (−5k) → cộng dồn không thể tránh.
3. Sau ~361 ván, biên nhà cái áp đảo may rủi.
4. Martingale & parlay chỉ làm cháy tài khoản nhanh hơn.
5. Soi kèo, rollover chỉ khiến chơi nhiều hơn → thua nhiều hơn.

**Bài học:** Cách thắng duy nhất là **không chơi**.

---

## Phụ lục — Công thức tra cứu nhanh

| Khái niệm | Công thức |
|-----------|-----------|
| Xác suất ngầm | `1 / odds` |
| Overround | `Σ(1/oddsᵢ) − 1` |
| Hold | `overround / (1 + overround)` |
| EV mỗi ván | `p·stake·(odds−1) − (1−p)·stake` |
| Biên nhà cái | `5 · n` |
| Dao động may rủi | `95 · √n` |
| Điểm giao | `n = 361` |
| Martingale net | `100 − 10·2^k` |
| Parlay margin | `1 − 0.95^k` |

*Đơn vị tiền: nghìn đồng (k). Ví dụ chuẩn: cược 100k, odds 1.90, p = 50%.*
