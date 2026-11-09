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
5. `supabase/migrations/202611080003_listening_time.sql`
6. `supabase/migrations/202611080004_profile_avatars.sql`
7. `supabase/migrations/202611080005_premium_vnpay.sql`
8. `supabase/migrations/202611080006_premium_zalopay.sql`
9. `supabase/migrations/202611080007_restore_premium_vnpay.sql`
10. `supabase/migrations/202611090001_profile_avatar_sync.sql`

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

Để tải batch 32 MP3 mới trong `..\music_data`, kiểm tra và cập nhật metadata
tại `supabase/music_metadata_new.csv`. CSV này được tạo từ tag ID3; `title` và
`artist` đã có khi đọc được, còn `genres` và `cover_filename` có thể điền trước
khi import. Tên file trong cột `filename` phải khớp chính xác với MP3.

Chạy lệnh sau trong PowerShell trên máy admin tin cậy. Script dùng thư mục nhạc
và CSV mới làm mặc định, đồng thời sẽ yêu cầu Secret/service-role key nếu chưa
có trong môi trường:

```powershell
.\supabase\scripts\import_new_music.ps1
```

Có thể truyền thư mục hoặc CSV khác bằng tham số `-MusicDirectory` và
`-MetadataCsv`. Wrapper xác nhận danh sách MP3 và CSV khớp nhau trước khi tải;
nó gọi `import_tracks.mjs` để tải MP3 lên bucket riêng `tracks`, cập nhật
catalog và đồng bộ thể loại. `supabase/music_metadata.csv` là CSV cũ của batch
43 bài, có tên file không thuộc thư mục hiện tại; không dùng CSV đó cho lệnh
batch mới. Không mở quyền ghi Storage cho người dùng ứng dụng để khắc phục lỗi
import `403`; hãy kiểm tra Secret/service-role key và project URL.

## Kiểm tra và build Android

```powershell
flutter analyze
flutter test
flutter build apk --release --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

APK đầu ra ở `build/app/outputs/flutter-apk/app-release.apk`. Bản hiện tại dùng
debug signing config cho release; cấu hình signing riêng trước khi phát hành.
