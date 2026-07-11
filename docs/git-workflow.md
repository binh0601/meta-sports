# Quy trình Git của nhóm — Mega Sports (house_edge_demo)

Tài liệu bắt buộc đọc trước khi code. Áp dụng cho mọi thành viên và mọi AI tool
(Claude Code, Copilot...). Bản rút gọn cho AI nằm trong `CLAUDE.md` — nội dung
hai file phải khớp nhau, sửa một nơi thì sửa cả nơi kia.

## Nguyên tắc số 1

> `main` luôn ổn định: checkout về là build được, `flutter test` pass.
> **Không ai push thẳng lên `main`** — kể cả người tạo repo.
> Mọi thay đổi (code, docs, test) đều đi qua branch riêng + Pull Request.

## Trước khi code — checklist 4 bước

1. **Cập nhật main mới nhất:**
   ```bash
   git checkout main
   git pull
   ```
2. **Xem mình định làm gì** — đọc plan trong `plans/` hoặc issue được giao.
   Chưa rõ yêu cầu thì hỏi trong nhóm trước, đừng code mò.
3. **Tạo branch từ main, đặt tên đúng chuẩn** (xem mục dưới):
   ```bash
   git checkout -b feat/ten-tinh-nang
   ```
4. **Chạy thử trước khi sửa:** `flutter pub get` + `flutter test` để chắc
   mình bắt đầu từ trạng thái xanh. Test đỏ ngay từ đầu → báo nhóm, không
   phải lỗi của bạn.

## Đặt tên branch

Cấu trúc: `<loại>/<mô-tả-ngắn-tiếng-anh-kebab-case>`

| Loại | Dùng khi | Ví dụ |
|------|----------|-------|
| `feat/` | Thêm tính năng | `feat/wallet-rollover` |
| `fix/` | Sửa lỗi | `fix/login-crash-on-empty-email` |
| `refactor/` | Sửa cấu trúc code, không đổi hành vi | `refactor/split-game-state` |
| `test/` | Chỉ thêm/sửa test | `test/wallet-edge-cases` |
| `docs/` | Chỉ sửa tài liệu | `docs/team-git-workflow` |
| `chore/` | Việc lặt vặt (deps, config) | `chore/bump-firebase` |

- Chữ thường, nối bằng `-`, tiếng Anh, đọc tên hiểu ngay nội dung.
- Một branch = một việc. Làm 2 tính năng → 2 branch.

## Commit

Theo **Conventional Commits**: `<type>: <mô tả ngắn>` (type giống bảng trên,
thêm `perf:`, `style:`).

- ✅ `feat: add wallet screen with rollover progress`
- ✅ `fix: prevent bet when stake exceeds balance`
- ❌ `update code`, `fix bug`, `commit lan 3`, `asdfgh`
- Commit nhỏ, mỗi commit một ý; commit thường xuyên, đừng dồn 1 cục cuối ngày.
- Mô tả bằng tiếng Anh, viết được tiếng Việt không dấu nếu bí từ.

## Trước khi push — bắt buộc

```bash
flutter analyze   # phải "No issues found!"
flutter test      # phải pass 100% — cấm skip/xóa test cho xanh
```

Lưu ý Windows: chạy test theo cả file (`flutter test test/widget_test.dart`),
đừng dùng `--plain-name` với tên test có dấu cách (flutter tools crash).

## Pull Request

1. Push branch: `git push -u origin feat/ten-tinh-nang`
2. Mở PR vào `main` trên GitHub. Mô tả PR phải có:
   - **Làm gì:** 2-3 dòng tóm tắt.
   - **Test thế nào:** lệnh đã chạy, đã thử tay trên emulator chưa.
   - Link plan/spec liên quan (nếu có).
3. Gắn ít nhất **1 người khác review**. Người review: đọc diff, chạy thử
   nếu nghi ngờ, comment thẳng thắn — approve rồi mới merge.
4. Merge bằng **Squash and merge** (lịch sử main gọn, 1 PR = 1 commit).
5. Merge xong **xóa branch** trên GitHub.

## Khi branch bị tụt so với main

Người khác merge PR trước bạn → branch của bạn cũ:

```bash
git checkout feat/ten-tinh-nang
git pull origin main        # keo main moi nhat vao branch minh
# tu xu ly conflict neu co, chay lai flutter test, roi push
```

Tự xử lý conflict trong branch của mình **trước khi** nhờ review.

## Cấm tuyệt đối

- Push / force-push thẳng lên `main`.
- Commit: `.claude/`, `android/local.properties`, keystore (`*.jks`,
  `key.properties`), **API key** (Groq, Firebase secret), file build output.
  Đã có `.gitignore` — đừng bao giờ `git add -f`.
- Commit code không compile lên branch có người khác cùng làm.
- Sửa/xóa test chỉ để build xanh — test fail là tín hiệu, không phải vật cản.

## Tóm tắt lệnh nhanh

```bash
git checkout main && git pull                  # 1. cap nhat
git checkout -b feat/ten-tinh-nang             # 2. tao branch
# ... code + commit nho ...
flutter analyze && flutter test                # 3. kiem tra
git push -u origin feat/ten-tinh-nang          # 4. push
# 5. mo PR tren GitHub -> nho review -> squash merge -> xoa branch
```
