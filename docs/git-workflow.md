# Quy trình Git của nhóm — Mega Sports (house_edge_demo)

Tài liệu bắt buộc đọc trước khi code. Áp dụng cho mọi thành viên và mọi AI tool
(Claude Code, Copilot...). Bản rút gọn cho AI nằm trong `CLAUDE.md` — nội dung
hai file phải khớp nhau, sửa một nơi thì sửa cả nơi kia.

## Nguyên tắc số 1

> `main` và `dev` là nhánh chung: **không ai push thẳng** — kể cả người tạo repo.
> Mọi thay đổi (code, docs, test) đi qua branch riêng + Pull Request, và chỉ
> **chủ repo (binh0601) review + merge**.

## Mô hình nhánh & quyền

```
feature branch ──PR──▶ dev ──PR (theo milestone)──▶ main
```

- **`main`**: bản ổn định để nộp/demo. Chỉ nhận PR từ `dev`.
- **`dev`**: nhánh tích hợp hằng ngày. PR tính năng trỏ vào đây.
- **Feature branch**: nơi duy nhất được push trực tiếp. Cả nhóm là
  collaborator của repo chung — push branch của mình lên repo, KHÔNG cần fork.
- **Review**: mọi PR do **chủ repo (binh0601) review và merge** — quy tắc này
  được GitHub khóa cứng bằng branch protection + CODEOWNERS (`.github/CODEOWNERS`):
  push thẳng vào `main`/`dev` sẽ bị từ chối, PR chưa có approve của chủ repo
  thì nút merge không bấm được.
- **Firebase**: `android/app/google-services.json` KHÔNG có trong repo
  (repo public) — xin file từ trưởng nhóm qua chat nhóm, đặt vào `android/app/`.
  Tuyệt đối không commit file này.

## Trước khi code — checklist 4 bước

1. **Cập nhật dev mới nhất:**
   ```bash
   git checkout dev
   git pull
   ```
2. **Xem mình định làm gì** — đọc plan trong `plans/` hoặc issue được giao.
   Chưa rõ yêu cầu thì hỏi trong nhóm trước, đừng code mò.
3. **Tạo branch từ dev, đặt tên đúng chuẩn** (xem mục dưới):
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
2. Mở PR vào `dev` trên GitHub (PR `dev` → `main` chỉ chủ repo mở theo
   milestone). Mô tả PR phải có:
   - **Làm gì:** 2-3 dòng tóm tắt.
   - **Test thế nào:** lệnh đã chạy, đã thử tay trên emulator chưa.
   - Link plan/spec liên quan (nếu có).
3. Người review là **chủ repo (binh0601)**: đọc diff, chạy thử nếu nghi ngờ,
   comment thẳng thắn — approve rồi mới merge. Không tự merge PR của mình
   (trừ chủ repo).
4. Merge bằng **Squash and merge** (lịch sử main gọn, 1 PR = 1 commit).
5. Merge xong **xóa branch** trên GitHub.

## Khi branch bị tụt so với dev

Người khác merge PR trước bạn → branch của bạn cũ:

```bash
git checkout feat/ten-tinh-nang
git pull origin dev         # keo dev moi nhat vao branch minh
# tu xu ly conflict neu co, chay lai flutter test, roi push
```

Tự xử lý conflict trong branch của mình **trước khi** nhờ review.

## Cấm tuyệt đối

- Push / force-push thẳng lên `main` hoặc `dev`.
- Commit: `.claude/`, `android/local.properties`, keystore (`*.jks`,
  `key.properties`), **API key** (Groq, Firebase secret), file build output.
  Đã có `.gitignore` — đừng bao giờ `git add -f`.
- Commit code không compile lên branch có người khác cùng làm.
- Sửa/xóa test chỉ để build xanh — test fail là tín hiệu, không phải vật cản.

## Tóm tắt lệnh nhanh

```bash
git checkout dev && git pull                   # 1. cap nhat
git checkout -b feat/ten-tinh-nang             # 2. tao branch
# ... code + commit nho ...
flutter analyze && flutter test                # 3. kiem tra
git push -u origin feat/ten-tinh-nang          # 4. push
# 5. mo PR vao dev -> chu repo review -> squash merge -> xoa branch
```
