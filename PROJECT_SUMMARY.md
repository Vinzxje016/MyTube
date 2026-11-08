# Tổng quan project MyTube

## 1. Mục tiêu

MyTube là ứng dụng nghe nhạc xây dựng bằng Flutter. Ứng dụng kết hợp giao diện khám phá và phát nhạc với Supabase để xác thực người dùng, lưu catalog bài hát, playlist cá nhân, bài hát yêu thích và lịch sử nghe. Giao diện và nội dung hiện hướng tới trải nghiệm tiếng Việt.

## 2. Công nghệ

- **Flutter / Dart**: ứng dụng đa nền tảng; cấu hình hiện có cho Android và Windows.
- **Supabase** (`supabase_flutter`): đăng nhập email/mật khẩu, PostgreSQL, Row Level Security và Storage.
- **just_audio**, **audio_service**, **just_audio_background**: phát nhạc từ URL, metadata và thông báo phát nền trên Android.
- **google_fonts**: kiểu chữ; giao diện dùng Material và theme tối.
- **Node.js**: script quản trị để nhập file MP3 lên Supabase.

Phiên bản SDK Dart tối thiểu theo `pubspec.yaml` là `^3.11.0`.

## 3. Cấu trúc mã nguồn

```text
lib/
  main.dart                    Khởi tạo Flutter, audio nền và Supabase
  config/supabase_config.dart  Đọc cấu hình Supabase từ dart-define
  controllers/                 Trạng thái phát nhạc dùng chung
  models/                      Song, Playlist, Artist, ChatMessage và dữ liệu mẫu
  screens/                     Đăng nhập, shell, khám phá, tìm kiếm, thư viện, hồ sơ,
                               phát nhạc, chi tiết playlist và chat AI DJ
  services/                    MusicRepository và AI gợi ý theo luật
  theme/                       Theme của ứng dụng
  widgets/                     Song card/tile, mini-player, equalizer
supabase/
  migrations/                  Schema, chỉ mục, policy RLS và Storage bucket
  scripts/import_tracks.mjs    Nhập MP3 vào catalog
test/                           Widget/unit tests hiện có
android/, windows/              Runner và cấu hình nền tảng
```

## 4. Các luồng chức năng

### Khởi động và xác thực

`main.dart` cấu hình thanh hệ thống, khởi tạo audio notification trên Android, rồi khởi tạo Supabase nếu có đủ biến môi trường. Nếu thiếu cấu hình, app hiển thị hướng dẫn thiết lập. Khi đã cấu hình, `AuthGate` điều hướng người dùng đã có session vào `MainShell`; người chưa đăng nhập thấy form đăng nhập/đăng ký email và mật khẩu.

### Khám phá và tìm kiếm

Màn **Khám phá** tải bài hát và playlist qua `MusicRepository`, đồng thời hiển thị nội dung đề xuất. Màn **Tìm kiếm** lọc catalog theo tên bài hát/nghệ sĩ và có lối vào AI DJ. Các mục nội dung mẫu như nghệ sĩ, thể loại và một số playlist được khai báo trong `MusicData`.

### Phát nhạc

`MusicPlayerController` là singleton `ChangeNotifier`, nắm bài hiện tại, queue, trạng thái phát, tiến độ, shuffle, repeat và danh sách liked trong bộ nhớ. Bài từ catalog có signed URL và được phát qua `just_audio`; audio nền Android dùng `just_audio_background`. Nếu bài không có `audioUrl`, controller dùng timer giả lập tiến độ. Mini-player và màn Now Playing quan sát controller này.

### Thư viện cá nhân

`MusicRepository` đọc/ghi playlist, thứ tự bài trong playlist, liked songs và listening history. Màn thư viện tải playlist, yêu thích và lịch sử của tài khoản hiện tại. Hồ sơ hiển thị thông tin tài khoản và hỗ trợ đăng xuất.

### AI DJ

`AiMusicService` gọi Supabase Edge Function `ai-dj`, dùng Gemini để hội thoại về âm nhạc và tạo đề xuất. Function xác thực JWT, đọc catalog/liked/history dưới RLS, chỉ chấp nhận ID bài có trong catalog và trả lời từ chối cố định cho yêu cầu ngoài âm nhạc. Khi người dùng yêu cầu tạo playlist, AI trả bản nháp; người dùng có thể đổi tên/bỏ bài rồi xác nhận lưu. Cần deploy function và đặt `GEMINI_API_KEY` trong Supabase secrets; xem `supabase/README.md`.

## 5. Backend Supabase

Migration `supabase/migrations/202611070001_initial_music_schema.sql` tạo các bảng:

| Bảng | Vai trò |
| --- | --- |
| `songs` | Catalog bài hát, đường dẫn audio/cover và trạng thái hoạt động |
| `genres` | Danh mục thể loại có mã và tên hiển thị |
| `song_genres` | Liên kết nhiều mã thể loại với từng bài hát |
| `playlists` | Playlist thuộc về người dùng |
| `playlist_songs` | Bài hát và vị trí sắp xếp trong playlist |
| `liked_songs` | Quan hệ người dùng - bài hát yêu thích |
| `listening_history` | Các lần bắt đầu nghe |

Migration `202611080001_normalize_song_genres.sql` bổ sung bảng `genres` và
bảng liên kết `song_genres`, để một bài hát tham chiếu nhiều mã thể loại. Cột
`songs.tags` được giữ để tương thích dữ liệu/import cũ; app lấy tên nhãn từ
quan hệ thể loại.

Các bảng bật RLS; policy giới hạn playlist, liked songs và history theo `auth.uid()`. Catalog chỉ cho client đã xác thực đọc bài đang hoạt động. Storage có bucket `tracks` riêng tư (MP3) và bucket `covers` công khai (JPEG/PNG/WebP). Ứng dụng tạo signed URL có thời hạn 3600 giây cho audio.

## 6. Thiết lập và chạy

1. Tạo project Supabase, chạy SQL migration ở trên và bật email/password trong Authentication.
2. Cài dependencies bằng `flutter pub get`.
3. Truyền URL và publishable key khi chạy:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Không đưa `service_role` key vào ứng dụng Flutter. Để nhập nhạc, thiết lập `SUPABASE_URL` và `SUPABASE_SERVICE_ROLE_KEY` trong môi trường cục bộ, sau đó chạy:

```powershell
node supabase/scripts/import_tracks.mjs 'D:\path\to\music_data'
```

Script chỉ nhập MP3, lấy tên và nghệ sĩ từ tên file có dạng `Tên bài - Nghệ sĩ.mp3`; SHA-256 của nội dung được dùng làm object path để lần nhập lại có thể upsert cùng catalog row. README Supabase ghi nhận thư mục nhạc hiện có 13 MP3 và 29 MP4; schema/script hiện chỉ nhận MP3.

## 7. Nhận xét trạng thái hiện tại

- README gốc vẫn là nội dung khởi tạo Flutter mặc định, chưa mô tả sản phẩm; tài liệu này bổ sung tổng quan ở mức project.
- Catalog và thư viện cá nhân đã có luồng Supabase, nhưng nhiều nội dung khám phá/AI vẫn phụ thuộc `MusicData.sampleSongs` và dữ liệu tĩnh.
- `MusicPlayerController` khởi tạo queue và liked IDs mẫu. Khi đồng bộ liked từ backend, cần chú ý vòng đời đăng nhập/đăng xuất để tránh hiển thị trạng thái bộ nhớ của tài khoản trước.
- Tìm kiếm repository hiện tải danh sách bài hoạt động rồi lọc title/artist ở client; không lọc album và không phân trang.
- Cấu hình platform trong repo có Android và Windows; chưa thấy thư mục iOS hoặc web trong danh sách file được kiểm tra.
- Bài hát nhập tự động có thể thiếu `duration_seconds` và `cover_path`; cần bổ sung metadata để thời lượng và bìa đầy đủ hơn.
- Lịch sử được ghi khi bắt đầu phát; signed URL audio hết hạn sau một giờ. Lỗi phát remote hiện được xử lý trong controller nhưng không đưa thông báo chi tiết tới giao diện.
- Test hiện có bao phủ một số logic model/controller/AI và smoke test điều hướng. Đây là mô tả phạm vi test từ mã nguồn, chưa phải kết quả chạy test trong lần phân tích này.

## 8. Điểm bắt đầu khi bảo trì

- Thay đổi schema/RLS/Storage: `supabase/migrations/` và `supabase/README.md`.
- Thay đổi đọc/ghi backend: `lib/services/music_repository.dart`.
- Thay đổi playback, queue, liked state: `lib/controllers/music_player_controller.dart`.
- Thay đổi đề xuất/chat: `lib/services/ai_music_service.dart` và `lib/screens/ai_chat_screen.dart`.
- Thay đổi điều hướng tổng: `lib/screens/main_shell.dart`; thay đổi xác thực: `lib/screens/auth_gate.dart`.

