# UI Visual Richness — hồ sơ căn chỉnh, ảnh cầu thủ, khử màu xám — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox syntax.

**Goal:** Sửa 4 khiếu nại của user: (1) tab Hồ sơ lệch/không căn chỉnh/đơn điệu; (2) match card toàn xám không hình ảnh; (3) banner quảng cáo chỉ chữ + màu, thiếu ảnh cầu thủ; (4) trang chi tiết trận cái nào cũng giống nhau, không effect.

**Hướng thiết kế (kế thừa design system đã chốt):** giữ brand xanh royal + gold + font RussoOne/ChakraPetch; tăng RICHNESS bằng ảnh thật có sẵn trong assets (5 ảnh action), gradient nhiều lớp thay màu phẳng, watermark texture, viền màu phân biệt section, stagger entrance. Không thêm ảnh mới (đủ 5 ảnh: player_volley, action_worldcup, action_stadium_flare, ball_closeup, stadium_night).

## Global Constraints

- Branch `feat/ui-visual-richness` (từ dev). PR vào dev. Sau mỗi task: analyze sạch + full test 52/52 + `git diff --numstat` từng file KHÔNG có line-ending flip (file đổi hàng trăm dòng cho edit nhỏ → checkout HEAD file đó, làm lại surgical) + commit conventional.
- Flutter qua Windows: `/mnt/c/Windows/System32/cmd.exe /c "cd /d D:\FPTk8\PRM\PE_PRM393_EXAMPLE\DeTest\DeTest\house_edge_demo && D:\FPTk8\PRM\flutter\bin\flutter.bat <cmd>"`. Git qua git.exe từ bash. Test theo FILE. Widget test: bounded pumps.
- Hiệu ứng: transform/opacity, 150-300ms, controller lặp dispose + static khi disableAnimations (pattern PulseDot/_KenBurns sẵn có).
- UI string tiếng Việt có dấu; comment không dấu; file <~200 dòng; KHÔNG đổi string test đang assert ('Nạp / Rút tiền', 'Chơi lại từ đầu', 'MEGA SPORTS', 'MỞ CƯỢC', 'WORLD CUP 2026'...).
- UI task được tinh chỉnh giá trị thị giác ±20% quanh spec; interface/logic đúng spec.
- Building blocks sẵn có: `displayStyle`/`kDisplayFont`/`kGold`/`kBrandGradient` (brand_colors), `EntranceSlide`/`ScaleTap`/`PulseDot`/`ShakeOnce` (motion_effects), `PitchBackground` (pitch_background), `MatchInsights`, ảnh trong assets/images/.

---

### Task 1: Hồ sơ (tab Tôi) — căn chỉnh + nâng cấp thị giác

**Files:** Modify `lib/widgets/stat_card.dart`, `lib/screens/player_profile_screen.dart`.

**Vấn đề gốc:** StatCard label dài ngắn khác nhau ('Số phiếu đã đấu' xuống 2 dòng, 'Lãi/lỗ' 1 dòng) → 3 card CAO THẤP LỆCH NHAU (Row default center); giá trị chữ nhỏ; body trống trải; nút đơn điệu.

**Spec:**
1. `StatRow`: bọc Row trong `IntrinsicHeight` + `crossAxisAlignment: CrossAxisAlignment.stretch` → 3 card luôn cao bằng nhau.
2. `StatCard` v2: thêm param optional `IconData? icon` và `Color? accentColor`. Layout mới căn GIỮA dọc-ngang: icon nhỏ 18px màu accent (nếu có) trên đầu → value chữ TO (`fontFamily: kDisplayFont`, size 18, tabular cảm giác) → label `bodySmall` textAlign center, maxLines 2. Card có viền trên 2px màu `accentColor ?? primary` (Container decoration, không đổi Card elevation). Import brand_colors.
   LƯU Ý: stat_card.dart được nhiều màn khác dùng (admin, summary...) — param mới phải optional để KHÔNG phá call site cũ; grep `StatCard(` toàn lib/ xác nhận không cần sửa nơi khác.
3. `player_profile_screen.dart`:
   - Header: avatar bọc ring gradient gold→blue (Container 4px padding, shape circle, gradient); username dùng `displayStyle(size: 22)`; pill 'Số dư' dùng kDisplayFont; badge nhỏ 'NGƯỜI CHƠI DEMO'/'THÀNH VIÊN' (isDemo ? demo : thành viên) dạng pill viền trắng alpha .3 thay Text thường.
   - Thành tích: truyền icon + accentColor cho 3 StatCard (receipt_long/blue, payments/gold, trending_up-hoặc-down/green-red theo netProfit).
   - Thêm card 'Điều kiện rút' mini khi `!authState.isDemo`: LinearProgressIndicator `g.wallet.progress` + text 'Đã cược X / cần Y' (fmtMoney) — tái dùng dữ liệu wallet, 1 Card ~15 dòng, đặt sau StatRow.
   - 3 nút: giữ nguyên labels; Nạp/Rút thành nút gradient brand (Ink decoration trong FilledButton.styleFrom backgroundColor transparent + Container gradient — hoặc đơn giản backgroundColor primary, đậm hơn tonal), cả 3 nút height 48 đồng nhất; icon size 20 đồng nhất.
   - Bọc các khối body trong `EntranceSlide(index: ...)` stagger.
   - File đang 186 dòng — sau sửa giữ <200; nếu vượt, tách widget `_ProfileHeader` sang cùng file vẫn được (1 file), KHÔNG tách file mới.

**Test:** không test mới; full suite pass (test 'tai khoan demo khong thay nut Nap/Rut' phụ thuộc text 'Nạp / Rút tiền' và 'Chơi lại từ đầu' — GIỮ NGUYÊN string).

**Commit:** `feat: align and enrich profile tab with stat icons and rollover mini card`

---

### Task 2: Banner quảng cáo có ảnh cầu thủ

**Files:** Modify `lib/widgets/promo_banner_carousel.dart`.

**Spec:**
1. `_Promo` thêm field `final String image;` — gán 4 ảnh: 'NẠP LẦN ĐẦU +100%' → `assets/images/action_stadium_flare.jpg`; 'CƯỢC XÂU THƯỞNG KHỦNG' → `assets/images/player_volley.jpg`; 'SIÊU KÈO CUỐI TUẦN' → `assets/images/action_worldcup.jpg`; 'MỜI BẠN NHẬN 50K' → `assets/images/ball_closeup.jpg`.
2. Item layout thành Stack (ClipRRect radius 12): (a) `Image.asset(p.image, fit: BoxFit.cover, alignment Alignment(0,-.3))`; (b) gradient overlay TRÁI→PHẢI từ màu banner: `[p.colors.first alpha .95, p.colors.last alpha .55, transparent-ish alpha .15]` để chữ bên trái nổi mà ảnh bên phải lộ rõ; (c) Row nội dung như cũ (icon + title + subtitle + chevron). Title dùng `displayStyle(size: 15)`.
3. Height carousel 96 → 112 (ảnh thở hơn). Giữ shimmer overlay + dots + timer như cũ.
4. Chấm chỉ số trang active đổi thành gold dài 16px (đã gần vậy — giữ/tinh chỉnh).

**Test:** không test mới; full suite pass (không string nào bị assert).

**Commit:** `feat: player imagery backgrounds on promo banners`

---

### Task 3: Match card hết xám — gradient, texture, VS

**Files:** Modify `lib/widgets/match_card.dart` (đọc kỹ toàn file trước).

**Spec:**
1. Nền card: thay Card mặc định bằng Container decoration gradient dọc tinh tế `[Color(0xFF1E2749), Color(0xFF141A33)]` + border trắng alpha .06 radius 16 (giữ margin/padding hiện có). Nếu match.played → gradient xám đậm hơn hiện trạng nhưng vẫn 2 stops.
2. Watermark texture: Positioned góc phải-dưới `Icon(Icons.sports_soccer, size: 96, color: Colors.white.withValues(alpha: .045))` bên trong ClipRRect — card không còn phẳng mà không cần ảnh per-card.
3. Giữa 2 nút odds: cột 'VS' nhỏ (`displayStyle(size: 12, color: kGold.withValues(alpha:.8))`) thay SizedBox trống (nếu layout hiện là Row 2 Expanded + gap — chèn giữa).
4. OddsSelectButton khi KHÔNG chọn: nền gradient nhẹ `[white alpha .07, white alpha .03]` + border trắng alpha .1 (thay xám phẳng); tên đội weight 600; odds giữ kDisplayFont. Selected/placed giữ nguyên glow gold + tint hiện có.
5. Badge kickoff (17:00...): pill gradient brand nhẹ thay nền xám.

**Test:** không test mới; full suite pass (match card xuất hiện trong widget tests — không đổi text 'MỞ CƯỢC', tên đội, odds format).

**Commit:** `feat: gradient depth, soccer watermark and vs divider on match cards`

---

### Task 4: Trang chi tiết trận — mỗi trận một sắc thái + entrance effects

**Files:** Modify `lib/screens/match_detail_screen.dart`, có thể `lib/widgets/ai_analysis_card.dart` (viền accent).

**Spec:**
1. Hero ảnh xoay theo trận: `final heroImage = ['assets/images/stadium_night.jpg', 'assets/images/action_worldcup.jpg', 'assets/images/action_stadium_flare.jpg'][match.id % 3];` — thay ảnh cứng stadium_night. Giữ gradient overlay.
2. Section accent: mỗi section một màu viền trái 3px (Container decoration border left, padding left 10, bọc quanh nội dung dưới mỗi SectionTitle — hoặc gắn màu vào SectionTitle bằng Row [thanh dọc màu 4x16 + text]): 'Nhận định chuyên gia' → Color(0xFF3B82F6); 'AI nhận định' → kGold; 'Phong độ 5 trận' → Color(0xFF22C55E); 'Đối đầu gần đây' → Color(0xFFA855F7); 'Cộng đồng đang đặt' → Color(0xFFF97316). Cách gọn nhất: thêm widget nội bộ `_AccentSectionTitle(text, color)` (Row thanh màu + SectionTitle-style text) thay SectionTitle tại 5 chỗ — KHÔNG đổi SectionTitle dùng chung.
3. Entrance: bọc từng section block trong `EntranceSlide(index: i)` (import motion_effects) — các khối trượt vào so le khi mở màn.
4. Splitbar % (chuyên gia/cộng đồng): bo tròn đầu thanh (đã ClipRRect 6 — tăng 8) + chiều cao 14→16, % text đậm hơn (w700).
5. H2H card: mỗi dòng đối đầu thêm icon `Icons.sports_score` 14px xám + tỷ số bọc `fontWeight w700`.
6. File 261 dòng — cho phép tới ~290 (đã vượt guideline từ trước, KHÔNG tách file trong plan này; ghi concern nếu vượt 300).

**Test:** không test mới; full suite pass.

**Commit:** `feat: per-match hero variety, accent sections and staggered detail reveal`

---

### Task 5 (chốt): full check + push + PR

- analyze sạch, full test 52/52, build apk --debug OK.
- Whole-branch review (controller dispatch) với các Minor tồn đọng.
- Push `feat/ui-visual-richness`, PR vào dev (controller soạn mô tả).

## Ghi chú
- "Hình cầu thủ trong từng match card": dùng watermark + gradient thay ảnh thật per-card (không có ảnh theo đội, nhét ảnh chung vào 8 card sẽ rối + nặng list). Ảnh cầu thủ tập trung ở hero + banner + detail — đúng chỗ đắt giá.
- Emulator 4GB: ảnh banner dùng chung asset đã nạp, không thêm ảnh mới → không tăng RAM đáng kể.
