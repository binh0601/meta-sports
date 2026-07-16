# SPEC — XÁC SUẤT 30 (Đồ án học tập / demo kỹ thuật)

> Phạm vi: đây là đặc tả cho một **ứng dụng mô phỏng giáo dục**, dùng để học về
> RNG, state machine, hệ số tỷ lệ cược và khái niệm house edge.
> **Không có tiền thật, không nạp/rút, không cổng thanh toán.** "Xu" là điểm ảo
> tồn tại trong bộ nhớ của app, mất khi đóng app (trừ khi có yêu cầu lưu cục bộ
> ở mục 9).

---

## 1. Tổng quan

| Mục | Nội dung |
|---|---|
| Tên | Xác Suất 30 |
| Loại hình | Ứng dụng mô phỏng single-player, không multiplayer, không server |
| Đơn vị tiền tệ | Xu ảo (virtual points), không quy đổi tiền thật |
| Nền tảng đích | Flutter (Android/iOS/Web) |
| Mục tiêu học thuật | Minh hoạ state machine theo thời gian, RNG, kỳ vọng toán học (expected value), house edge |

---

## 2. Thuật ngữ (Glossary)

- **Kỳ (Round)**: một chu kỳ chơi hoàn chỉnh, có ID duy nhất, kéo dài `total` giây.
- **Pha (Phase)**: trạng thái của kỳ — `betting` (nhận cược) → `locked` (khoá, chờ) → `resolved` (đã có kết quả).
- **Cược (Bet)**: một lượt đặt gồm `kind` (loại), `value` (giá trị), `amount` (số xu).
- **Kết quả (Result)**: số nguyên ngẫu nhiên 0–9 do RNG sinh ra khi kết thúc kỳ.
- **Hệ số (Odds/Multiplier)**: tỷ lệ nhân trên số xu đặt (đã trừ phí) nếu thắng.
- **Khấu trừ (Deduction)**: 2% phí trên mỗi lượt đặt trước khi tính thưởng.
- **House edge**: biên lợi thế toán học nghiêng về "nhà cái" mô phỏng, phát sinh từ khấu trừ 2%.

---

## 3. Luật chơi

### 3.1 Loại cược và hệ số thưởng

Tất cả hệ số áp dụng trên `stake_effective = stake * 0.98`.

| Loại cược | Giá trị | Điều kiện thắng | Hệ số |
|---|---|---|---|
| Màu — Xanh | `green` | Kết quả ∈ {1,3,7,9} | ×2 |
| Màu — Xanh | `green` | Kết quả = 5 | ×1.5 |
| Màu — Đỏ | `red` | Kết quả ∈ {2,4,6,8} | ×2 |
| Màu — Đỏ | `red` | Kết quả = 0 | ×1.5 |
| Màu — Tím | `purple` | Kết quả ∈ {0,5} | ×4.5 |
| Số | `0`–`9` | Kết quả = số đã chọn | ×9 |
| Kích cỡ — Lớn | `big` | Kết quả ∈ {5,6,7,8,9} | ×2 |
| Kích cỡ — Nhỏ | `small` | Kết quả ∈ {0,1,2,3,4} | ×2 |

Bảng màu số (dùng để tô UI và tính thắng/thua):

```
0 → đỏ + tím (số kép)
1 → xanh
2 → đỏ
3 → xanh
4 → đỏ
5 → xanh + tím (số kép)
6 → đỏ
7 → xanh
8 → đỏ
9 → xanh
```

### 3.2 Ràng buộc đặt cược (validation rules)

| # | Luật | Cách xử lý |
|---|---|---|
| R1 | Không được đặt cược 2 bên đối lập trong cùng kỳ (Lớn & Nhỏ) | Từ chối lượt đặt thứ 2, hiện thông báo |
| R2 | Không được đặt từ 8 số riêng biệt trở lên trong cùng kỳ | Từ chối khi số riêng biệt sắp vượt quá 7 |
| R3 | Số xu đặt phải > 0 và ≤ số dư hiện có | Từ chối, hiện thông báo |
| R4 | Chỉ được đặt cược khi pha = `betting` | Nút đặt cược bị khoá khi pha khác |

### 3.3 Vòng đời một kỳ (round lifecycle)

```
[betting: 0s → betting_duration]
        │  (nhận cược, đếm ngược hiển thị)
        ▼
[locked: betting_duration → total_duration]
        │  (không nhận cược mới, chờ mở kết quả)
        ▼
[resolved: total_duration]
        │  (RNG sinh kết quả 0–9, đối chiếu tất cả cược, cộng/trừ số dư,
        │   ghi log lịch sử)
        ▼
   (delay ngắn 1.5–2s hiển thị kết quả) → khởi tạo kỳ mới, seq += 1
```

Cấu hình thời lượng:

| Chế độ | Tổng thời gian | Thời gian nhận cược | Thời gian khoá |
|---|---|---|---|
| Thực | 30s | 25s | 5s |
| Nhanh (demo) | 8s | 6s | 2s |

Tỷ lệ `betting : locked = 25 : 5 = 5 : 1` được giữ nguyên ở mọi chế độ.

### 3.4 Sinh kết quả (RNG)

- Kết quả là số nguyên ngẫu nhiên đều (uniform) trong khoảng [0, 9].
- Bản demo dùng RNG chuẩn của ngôn ngữ (`Random()` trong Dart / `Math.random()` trong JS) — **không phải RNG bảo mật**, chỉ phục vụ mục đích học tập.
- Ghi chú kỹ thuật: nếu triển khai thực tế cần công bằng có thể kiểm chứng, cần cơ chế commit-reveal hoặc RNG từ server có kiểm toán — nằm ngoài phạm vi bản demo này.

### 3.5 Công thức thanh toán

```
stake_effective = stake_amount × 0.98
if (điều kiện thắng thoả mãn):
    payout = stake_effective × multiplier
    net_change = payout − stake_amount
else:
    net_change = −stake_amount
new_balance = old_balance + net_change
```

---

## 4. Mô hình dữ liệu (Data model)

### 4.1 `Bet`
| Trường | Kiểu | Mô tả |
|---|---|---|
| kind | enum: `color`, `number`, `size` | Loại cược |
| value | dynamic (String hoặc int) | Giá trị cụ thể: `green`/`red`/`purple`, 0–9, `big`/`small` |
| amount | double | Số xu đặt |

### 4.2 `RoundState`
| Trường | Kiểu | Mô tả |
|---|---|---|
| roundId | String | Định danh kỳ, ví dụ `20260714100050904` |
| seq | int | Số thứ tự kỳ, tăng dần |
| phase | enum: `betting`, `locked`, `resolved` | Pha hiện tại |
| remainingMs | int | Số mili-giây còn lại của kỳ |
| result | int? | Kết quả 0–9, null nếu chưa mở |
| pendingBets | List\<Bet\> | Danh sách cược đang chờ của kỳ |

### 4.3 `HistoryEntry`
| Trường | Kiểu | Mô tả |
|---|---|---|
| roundId | String | Kỳ tương ứng |
| result | int | Kết quả |
| colorTag | String | `green` / `red` / `green-purple` / `red-purple` |
| size | String | `Lớn` / `Nhỏ` |
| netChange | double | Lãi/lỗ ròng của kỳ đó |
| hadBets | bool | Có đặt cược trong kỳ đó không |

### 4.4 `GameStats` (theo dõi house edge)
| Trường | Kiểu | Mô tả |
|---|---|---|
| totalWagered | double | Tổng xu đã đặt từ đầu phiên |
| totalPaid | double | Tổng xu đã trả thưởng từ đầu phiên |
| actualEdgePct | double? | `(totalWagered − totalPaid) / totalWagered × 100` |

---

## 5. Kiến trúc đề xuất cho bản Flutter

```
lib/
 ├─ main.dart                 // Entry point, MaterialApp, ChangeNotifierProvider
 ├─ models.dart                // Enum, class Bet/HistoryEntry, hàm evaluateBet(), bảng ODDS
 └─ game_controller.dart       // GameController extends ChangeNotifier — chứa toàn bộ
                                  logic state machine, Timer, RNG, validate luật chơi
```

- **State management**: `ChangeNotifier` + `provider` package — đủ đơn giản cho quy mô đồ án, dễ giải thích trong báo cáo, không cần Bloc/Riverpod phức tạp.
- **Timer**: `Timer.periodic(Duration(milliseconds: 100), ...)` để tick UI mượt, tính `remaining` dựa trên `DateTime.now().difference(startTime)` (tránh lệch cộng dồn của cách đếm lùi trực tiếp).
- **UI**: `StatelessWidget`/`StatefulWidget` lắng nghe qua `Consumer<GameController>` hoặc `context.watch<GameController>()`.
- **Không dùng lưu trữ cục bộ** theo mặc định (đúng tinh thần "điểm ảo mất khi đóng app"); nếu muốn giữ số dư giữa các phiên có thể thêm `shared_preferences` — ghi rõ trong UI rằng đây chỉ là lưu tiến trình học tập, không phải giao dịch tài chính.

---

## 6. Yêu cầu phi chức năng (Non-functional requirements)

1. Không kết nối mạng, không cổng thanh toán, không thu thập dữ liệu định danh người dùng.
2. Toàn bộ số liệu (`balance`, `history`, `stats`) chỉ tồn tại trong bộ nhớ runtime.
3. UI phải hiển thị rõ nhãn "xu ảo / học tập" ở màn hình chính để tránh gây hiểu lầm là tiền thật.
4. Ứng dụng chạy offline hoàn toàn.
5. Hỗ trợ tối thiểu Android + iOS; Web là tuỳ chọn.

---

## 7. Checklist kiểm thử (test cases gợi ý)

- [ ] Đặt cược khi pha = `locked` → bị từ chối.
- [ ] Đặt cược Lớn rồi đặt Nhỏ trong cùng kỳ → bị từ chối ở lượt thứ 2.
- [ ] Đặt đủ 7 số riêng biệt, đặt số thứ 8 → bị từ chối.
- [ ] Đặt cược vượt quá số dư → bị từ chối.
- [ ] Kết quả = 0, có cược Đỏ và cược Tím → cả hai đều thắng đúng hệ số tương ứng (1.5 và 4.5).
- [ ] Kết quả = 5, có cược Xanh và cược Tím → cả hai đều thắng đúng hệ số tương ứng (1.5 và 4.5).
- [ ] Sau nhiều kỳ (>100), `actualEdgePct` hội tụ gần 2%.
- [ ] Đổi chế độ Thực ↔ Nhanh giữa chừng → reset kỳ hiện tại an toàn, không rò rỉ Timer cũ (nhớ `cancel()` timer trước khi tạo timer mới).

---

## 8. "Bóng đá hoá" — lớp trình bày (football framing)

> Toán học lõi ở mục 3 **giữ nguyên 100%**. Mục này chỉ đổi *nhãn + hình ảnh*
> để game hợp bối cảnh app cá cược bóng đá. Kết quả RNG 0–9 được diễn giải là
> **TỔNG BÀN THẮNG** của một "trận chớp nhoáng" (flash match) dài 30s.

Tên hiển thị: **KÈO CHỚP · 30 giây**. Vào bằng tab thứ 4 ở thanh điều hướng.

### 8.1 Ánh xạ loại cược

| Cược gốc (mục 3.1) | Kèo bóng đá | Thắng khi tổng bàn | Hệ số |
|---|---|---|---|
| Size Big | **TÀI** (nhiều bàn) | {5,6,7,8,9} | ×2 |
| Size Small | **XỈU** (ít bàn) | {0,1,2,3,4} | ×2 |
| Color Green | **LẺ** (tổng bàn lẻ) | {1,3,7,9} · {5} | ×2 · ×1.5 |
| Color Red | **CHẴN** (tổng bàn chẵn) | {2,4,6,8} · {0} | ×2 · ×1.5 |
| Color Purple | **ĐẶC BIỆT** (tịt ngòi 0 / mốc 5) | {0,5} | ×4.5 |
| Number 0–9 | **ĐÚNG TỔNG BÀN** | đúng số đã chọn | ×9 |

Tài/Xỉu (Over/Under) và Lẻ/Chẵn (Odd/Even goals) là kèo bóng đá có thật, nên
ánh xạ tự nhiên. Bảng màu số của mục 3.1 khớp y hệt: lẻ→xanh, chẵn→đỏ, {0,5}
thêm tím → dùng tô lưới số 0–9 và dải lịch sử.

### 8.2 Trình bày kết quả

- Reveal: bảng tỷ số 2 đội (huy hiệu + scoreline ngẫu nhiên có tổng = kết quả,
  ví dụ kết quả 7 → "4–3", kết quả 0 → "0–0"). **Chỉ tổng bàn** quyết định
  thắng/thua; cách chia scoreline là ngẫu nhiên trang trí, không ảnh hưởng toán.
- Dải lịch sử: chấm màu Lẻ/Chẵn/Đặc biệt kèm số tổng bàn (kiểu bảng cầu).

### 8.3 Không đổi so với mục 3–7

Vòng đời kỳ, thời lượng 30s/8s, khấu trừ 2%, house edge hội tụ ~2%, ràng buộc
R1–R4 (R1: Tài & Xỉu là cặp đối lập cấm đặt cả 2 cùng kỳ) và toàn bộ checklist
kiểm thử mục 7 áp dụng nguyên vẹn cho lớp bóng đá hoá.
