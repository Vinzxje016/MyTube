# MyTube

MyTube là ứng dụng nghe nhạc Flutter cho Android. Người dùng đăng ký và đăng
nhập bằng email; catalog nhạc dùng chung, còn playlist, bài yêu thích và lịch sử
nghe được lưu theo tài khoản. Audio MP3 được phát trực tuyến từ Supabase Storage.

## Yêu cầu

- Flutter SDK tương thích Dart `^3.11.0`.
- Project Supabase đã bật Email/Password Authentication.
- Android Studio hoặc thiết bị Android để chạy ứng dụng.

## Chuẩn bị Supabase

Mở SQL Editor và chạy các migration theo thứ tự:

1. `supabase/migrations/202611070001_initial_music_schema.sql`
2. `supabase/migrations/202611070002_song_source_filename.sql`
3. `supabase/migrations/202611080001_normalize_song_genres.sql`
4. `supabase/migrations/202611080002_seed_music_genres.sql`

Trong Authentication settings, bật xác minh email và cho phép redirect URI
`io.supabase.flutter://login-callback/`. Ứng dụng dùng URI này cho liên kết xác
nhận tài khoản và đặt lại mật khẩu.

## Chạy ứng dụng

Lấy Project URL và Publishable key từ đúng project Supabase. Chỉ dùng Publishable
key trong ứng dụng Flutter; không đưa Secret/service-role key vào client.

```powershell
flutter pub get
flutter run -d android --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Đăng ký tài khoản bằng email. Nếu xác minh email đang bật, mở thư xác nhận trên
thiết bị Android để quay lại ứng dụng.

## Gemini AI DJ

AI DJ dùng Gemini qua Supabase Edge Function; xem
[`supabase/README.md`](supabase/README.md#gemini-ai-dj) để tạo Gemini API key,
lưu key trong Supabase secrets và deploy function. Key không được đặt trong app.
AI chỉ hỗ trợ âm nhạc, chọn bài từ catalog hiện có và cho phép chỉnh bản nháp
playlist trước khi lưu.

## Nhập nhạc

Các MP3 nằm trong `..music_data`. Sửa metadata tại
`supabase/music_metadata.csv`; cột `filename` phải khớp đúng tên MP3 và nhiều
thể loại phân cách bằng dấu chấm phẩy trong cột `genres`.

Chạy import trong PowerShell trên máy admin tin cậy. Secret key chỉ được đặt
tạm trong terminal và cần thuộc cùng project với `SUPABASE_URL`:

```powershell
$env:SUPABASE_URL = 'https://PROJECT_REF.supabase.co'
$env:SUPABASE_SERVICE_ROLE_KEY = 'sb_secret_...'
node supabase/scripts/import_tracks.mjs '..\music_data' 'supabase\music_metadata.csv'
Remove-Item Env:SUPABASE_SERVICE_ROLE_KEY
```

Script tải MP3 lên bucket riêng `tracks`, cập nhật catalog và đồng bộ thể loại
vào `genres`/`song_genres`. Không mở quyền ghi Storage cho người dùng ứng dụng
để khắc phục lỗi import `403`; hãy kiểm tra Secret/service-role key và Project
URL có cùng project.

## Kiểm tra và build Android

```powershell
flutter analyze
flutter test
flutter build apk --release --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

APK đầu ra ở `build/app/outputs/flutter-apk/app-release.apk`. Bản hiện tại dùng
debug signing config cho release; cấu hình signing riêng trước khi phát hành.
