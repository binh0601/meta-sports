# Design: Trợ lý tìm kèo (NL bet finder) + Value indicator

Ngày: 2026-07-14. Trạng thái: đã được user duyệt qua brainstorming.

## Mục tiêu

1. **Trợ lý tìm kèo**: người chơi gõ câu hỏi tiếng Việt tự nhiên (vd "kèo cửa
   nhà dưới 2.0 trận World Cup") thay vì cuộn qua danh sách trận — LLM hiểu ý
   định, lọc và trả về đúng nhóm trận phù hợp; có fallback rule-based khi
   không có API key.
2. **Value indicator**: hiện "Edge +X%" và badge "VALUE" cạnh mỗi cửa cược,
   giúp người chơi thấy ngay kèo nào đang lệch giá so với ước tính chuyên gia
   — mà không tự tính tay.

Cả hai đều phục vụ mục tiêu demo môn PRM393: minh họa cách người chơi *cảm
thấy* mình đang có lợi thế, dù kỳ vọng dài hạn vẫn âm vì biên nhà cái đã trừ
sẵn trong odds.

## Giới hạn phạm vi (đã chốt với user)

- **Không thêm market mới.** App hiện chỉ có kèo thắng/thua 2 cửa (home/away),
  2 giải cố định (Cup Châu Á, World Cup), không có tài/xỉu, không có khái
  niệm giải đấu theo quốc gia (vd "Tây Ban Nha"). Trợ lý tìm kèo chỉ lọc trên
  dữ liệu đã có: tên đội, cửa nhà/khách, khoảng odds, giờ đá, giải hiện có.
  Câu ví dụ "tài xỉu... giải Tây Ban Nha" trong yêu cầu ban đầu chỉ minh họa
  *dạng* câu hỏi tự nhiên, không phải yêu cầu mở rộng model — việc đó (nếu
  cần) là một spec riêng sau này.
- **"Value" không phải edge thật.** Vì `oddsHome = 0.95 / trueProbHome` (và
  tương tự cho away), **mọi** kèo trong app đều có đúng -5% EV thật theo thiết
  kế — không kèo nào thực sự có lợi thế dương. "Edge" ở đây = chênh lệch giữa
  xác suất "chuyên gia" (`expertHomePct`, đã tồn tại trong `match_insights.dart`)
  và xác suất ngầm rút ra từ odds hiển thị. Đây là chỉ số **cảm nhận**, không
  phải lợi nhuận thật, và UI phải luôn nói rõ điều đó.

## Phần 1: Trợ lý tìm kèo

### Data flow

```
Câu hỏi (String)
  -> BetFinderService.parse(text, matches)
       có GROQ_API_KEY -> gọi Groq, yêu cầu trả JSON đúng schema BetQueryFilter
       không key / lỗi / timeout -> BetQueryParser.parse(text) (rule-based, local)
  -> BetQueryFilter
  -> filter.matches(match, onHome: ...) áp lên danh sách trận đang hiển thị
  -> UI ẩn/hiện MatchCard tương ứng + hiện chip mô tả filter đang áp
```

### Component

- **`lib/logic/bet_query_filter.dart`** (MỚI, Dart thuần, không import Flutter):
  ```dart
  class BetQueryFilter {
    final List<String> teamKeywords; // rong = khong loc theo ten doi
    final bool? sideHome;             // null = ca 2 cua
    final double? maxOdds;
    final double? minOdds;
    final League? league;
    const BetQueryFilter({...});
    const BetQueryFilter.empty();

    bool get isEmpty => ...; // dung de an/hien thanh filter dang ap

    /// true neu tran (o phia [onHome]) thoa man filter.
    bool matchesSide(FootballMatch m, bool onHome, League currentLeague);
  }
  ```
  So khớp tên đội: bỏ dấu tiếng Việt, không phân biệt hoa/thường, dùng
  `contains` (không cần match chính xác).
- **`lib/logic/bet_query_parser.dart`** (MỚI, Dart thuần): parser rule-based,
  luôn chạy được offline. Nhận diện:
  - Tên đội: so khớp với danh sách tên đội đang hiển thị trong vòng đấu hiện
    tại (truyền vào làm tham số, không hard-code danh sách đội).
  - Cửa: "nhà"/"chủ nhà" → `sideHome = true`; "khách" → `sideHome = false`.
  - Odds: regex bắt "dưới `<số>`" → `maxOdds`; "trên `<số>`" → `minOdds`.
  - Giải: "châu á" → `League.asianCup`; "world cup" → `League.worldCup`.
  - Không khớp gì → trả `BetQueryFilter.empty()` (không lọc, không báo lỗi).
- **`lib/services/bet_finder_service.dart`** (MỚI, mirror
  `AiAnalysisService`): input là câu hỏi + danh sách trận đang hiển thị (tên
  đội, giờ đá, odds, giải). Có `GROQ_API_KEY` → gọi Groq với system prompt yêu
  cầu **chỉ trả JSON** đúng schema `BetQueryFilter` (không giải thích thêm);
  parse JSON, lỗi format/timeout/status != 200 → fallback
  `BetQueryParser.parse`. Không có key → dùng thẳng parser local, không gọi
  mạng. Không cache theo câu hỏi (mỗi câu hỏi độc lập, không lặp lại như phân
  tích trận).
- **`lib/widgets/bet_finder_bar.dart`** (MỚI): ô tìm kiếm đặt ngay dưới
  `LeagueSwitcher` trong `SportsbookScreen`. Gõ xong bấm tìm (hoặc submit trên
  bàn phím) → gọi service (hiện loading nhỏ trong lúc chờ Groq) → cập nhật
  filter. Có filter đang áp: hiện 1 dòng chip tóm tắt (vd "Cửa nhà · dưới 2.0
  · World Cup") + nút "Xoá lọc". `SportsbookScreen` dùng filter để quyết định
  `MatchCard` nào hiển thị; không trận nào khớp → hiện dòng
  "Không tìm thấy kèo phù hợp, thử câu hỏi khác".
- **`lib/screens/sportsbook_screen.dart`** (SỬA): thêm state filter hiện tại
  (đơn giản: `ValueNotifier<BetQueryFilter>` hoặc field trong widget State),
  lọc `g.matches` trước khi render danh sách `MatchCard`.

### Edge case

- Câu hỏi rỗng hoặc chỉ có khoảng trắng → không gọi service, giữ nguyên danh
  sách đầy đủ.
- Cả 2 cửa của 1 trận đều không khớp filter (vd lọc theo tên đội cụ thể) →
  vẫn hiện `MatchCard` nếu **một trong hai cửa** khớp (để không ẩn nhầm trận
  đấu người chơi đang quan tâm).
- Groq trả JSON sai schema hoặc field lạ → fallback local parser, không throw
  ra UI (giữ nguyên nguyên tắc của `AiAnalysisService`: không bao giờ crash).
- Đổi giải (`LeagueSwitcher`) trong khi đang có filter → filter theo giải cũ
  không còn khớp trận nào → hiện thông báo trống, người chơi tự xoá lọc.

### Test

- **`test/bet_query_parser_test.dart`** (MỚI): parse các câu mẫu tiếng Việt
  ("kèo cửa nhà dưới 2.0", "world cup trên 1.8", tên đội cụ thể, câu vô nghĩa
  → filter rỗng) và assert đúng field.
- **`test/bet_query_filter_test.dart`** (MỚI): `matchesSide` với các tổ hợp
  filter (rỗng, chỉ odds, chỉ cửa, kết hợp).

## Phần 2: Value indicator

### Công thức

Thêm vào `lib/logic/match_insights.dart`, method trên `MatchInsights`:

```dart
/// Edge cam nhan: chenh lech xac suat chuyen gia vs xac suat ngam tu odds.
/// KHONG phai loi nhuan that - moi keo van co EV that ~-5% (overround).
double edgeFor(bool onHome, double odds) {
  final expertProb = (onHome ? expertHomePct : 100 - expertHomePct) / 100;
  return expertProb - BettingMath.impliedProb(odds);
}
```

Dương = "chuyên gia" đánh giá cửa này cao hơn tỷ lệ odds ngầm cho thấy (cảm
giác "hời"). Âm = ngược lại.

### Ngưỡng hiển thị

- Luôn hiện dòng nhỏ "Edge +X%"/"Edge -X%" (dùng `fmtPct` có sẵn trong
  `betting_math.dart`) dưới mỗi `OddsSelectButton` khi `!match.played` — kể cả
  âm, để không tạo cảm giác giấu số xấu.
- `edge >= 0.03` (từ +3 điểm phần trăm): thêm badge nhỏ màu gold "VALUE" cạnh
  tên đội trong `OddsSelectButton`.
- Trận đã đá (`match.played`): không hiện edge/badge nữa (không còn ý nghĩa).

### Component

- **`lib/logic/match_insights.dart`** (SỬA): thêm `edgeFor` như trên.
- **`lib/widgets/match_card.dart`** (SỬA) — trong `OddsSelectButton`:
  - Tính `ins = MatchInsights.of(match)` và `edge = ins.edgeFor(onHome, odds)`.
  - Thêm dòng `Text` nhỏ (fontSize ~9-10) ngay dưới dòng odds hiện tại: màu
    xanh nhạt nếu `edge > 0`, xám/outline nếu `edge <= 0`.
  - `edge >= 0.03`: thêm 1 `Container` badge nhỏ viền/nền gold, chữ "VALUE",
    đặt cạnh tên đội (cùng hàng, dùng `Row` đã có).
- **Disclaimer**: thêm icon `Icons.info_outline` nhỏ cạnh `BetFinderBar` (hoặc
  trong `AppBar` của `SportsbookScreen`) — bấm mở `AlertDialog` ngắn:
  "Edge tính từ chênh lệch giữa ước tính chuyên gia và tỷ lệ ngầm của kèo —
  không phải lợi nhuận thật, biên nhà cái (~5%) vẫn luôn trừ vào kỳ vọng dài
  hạn." Hiện 1 lần dễ thấy, không lặp lại disclaimer trên từng thẻ trận (tránh
  rối UI).

### Edge case

- `MatchInsights.of(match)` là hàm tất định (seed theo `match.id`), gọi lại
  nhiều lần trong `build()` không gây lệch dữ liệu — không cần cache thêm,
  giữ đơn giản (đã là pattern hiện có ở `ai_match_analysis.dart`).
- Cả 2 cửa cùng có edge dương (hiếm nhưng có thể xảy ra vì `expertHomePct` và
  `communityHomePct` là ước tính riêng, không nhất thiết cộng đủ 100% theo
  cách odds tính) → vẫn hiện badge cho cả 2, không cần xử lý đặc biệt.

### Test

- **`test/match_insights_test.dart`** (MỚI, hoặc thêm vào file test hiện có
  nếu đã tồn tại): kiểm tra `edgeFor` trả đúng dấu/giá trị cho vài case cụ thể
  (home/away, odds cao/thấp, expertPct khác nhau).

## Không làm trong scope này

- Không thêm market tài/xỉu hay giải đấu theo quốc gia.
- Không lưu lịch sử câu hỏi tìm kèo hay cá nhân hóa theo người dùng.
- Không thêm sắp xếp danh sách trận theo edge (chỉ lọc hiện/ẩn, không sort).
