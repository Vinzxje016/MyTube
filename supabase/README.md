# Thiết lập Supabase

## Áp dụng schema

Mở SQL Editor của project Supabase và chạy các migration theo thứ tự:

1. `migrations/202611070001_initial_music_schema.sql`
2. `migrations/202611070002_song_source_filename.sql`
3. `migrations/202611080001_normalize_song_genres.sql`
4. `migrations/202611080002_seed_music_genres.sql`
5. `migrations/202611080003_listening_time.sql`
6. `migrations/202611080004_profile_avatars.sql`
7. `migrations/202611080005_premium_vnpay.sql`
8. `migrations/202611080006_premium_zalopay.sql`
9. `migrations/202611080007_restore_premium_vnpay.sql`

Các migration tạo catalog nhạc, bảng playlist và lịch sử nghe theo tài khoản,
các chính sách Row Level Security (RLS), Storage bucket và khóa tên file nguồn
dùng để import nhiều lần. Migration `202611080002` tạo bảng `genres` và bảng liên kết
`song_genres`, đồng thời chuyển các thể loại hiện có sang mã thể loại.

Trong phần Authentication settings, bật đăng nhập bằng email/mật khẩu, xác minh
email và khôi phục mật khẩu. Thêm `io.supabase.flutter://login-callback/` vào
URL Configuration > Redirect URLs để liên kết xác nhận và khôi phục mở lại app
Android.

Migration `202611080004_profile_avatars.sql` tạo bucket công khai
`profile-avatars` (giới hạn ảnh 5 MB). Người dùng đã đăng nhập chỉ được tải lên,
cập nhật hoặc xóa ảnh trong thư mục có UID của chính mình; ảnh có thể được đọc
công khai để hiển thị hồ sơ. Trang Cá nhân cập nhật tên/avatar trong user
metadata. Email mới yêu cầu xác nhận qua email; mật khẩu mới được cập nhật bởi
Supabase Auth.

Migration `202611080005_premium_vnpay.sql` tạo subscription Premium và đơn hàng
VNPay. Migration `202611080006_premium_zalopay.sql` là phần thử nghiệm ZaloPay,
hiện không được app sử dụng. Migration `202611080007_restore_premium_vnpay.sql`
khôi phục bảng/RPC VNPay nếu đã xóa trước đó.

## Cấu hình Flutter

Truyền URL project và publishable key khi chạy ứng dụng. Không đưa khóa
`service_role` vào ứng dụng Flutter.

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

## Gemini AI DJ

AI DJ gọi Gemini từ Supabase Edge Function `ai-dj`. Khóa Gemini chỉ nằm trong
secrets của Supabase; không thêm khóa vào Flutter, `.env` phía client hoặc Git.
Function xác thực session người dùng, đọc catalog/liked/history theo RLS, và
chỉ trả ID bài hợp lệ trong catalog. Yêu cầu ngoài âm nhạc nhận câu từ chối cố
định. Playlist được tạo thành bản nháp để người dùng chỉnh và xác nhận trước
khi lưu. Function dùng Gemini Interactions API với phản hồi JSON có schema;
model mặc định là `gemini-3.5-flash-lite` để ưu tiên độ trễ thấp.

1. Tạo Gemini API key trong Google AI Studio.
2. Cài Supabase CLI, đăng nhập và liên kết đúng project:

```powershell
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

3. Tạo file `supabase/.env.ai.local` (file `.env.*` đã được Git bỏ qua) với:

```dotenv
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
GEMINI_MODEL=gemini-3.5-flash-lite
```

4. Đẩy secrets lên Supabase rồi deploy function:

```powershell
supabase secrets set --env-file supabase/.env.ai.local
supabase functions deploy ai-dj
```

Xóa file secret cục bộ sau khi deploy. Gọi lại `flutter run` với Supabase URL
và Publishable key như phần trên. Nếu function hoặc Gemini chưa cấu hình, chat
sẽ báo chưa kết nối được.

## Premium và VNPay Sandbox

AI DJ chỉ dùng được khi subscription còn hạn. App kiểm tra trạng thái để hiển
thị trang nâng cấp; Edge Function `ai-dj` kiểm tra lại phía server. Gói thử
nghiệm có giá 10.000đ/30 ngày. VNPay IPN server-to-server là nguồn duy nhất
để cấp quyền; URL Return chỉ hiển thị kết quả cho người dùng.

1. Đăng ký tài khoản VNPay Sandbox để nhận `TMN Code` và `Hash Secret`. Không
   đặt các giá trị này trong Flutter hoặc Git.
2. Đảm bảo migration `202611080005_premium_vnpay.sql` đã áp dụng. Nếu bảng
   VNPay từng bị xóa, áp dụng migration khôi phục `202611080007_restore_premium_vnpay.sql`.
3. Đặt secrets trong Supabase:

```powershell
supabase secrets set VNPAY_TMN_CODE=YOUR_TMN_CODE VNPAY_HASH_SECRET=YOUR_HASH_SECRET
```

4. Deploy ba function thanh toán và function AI:

```powershell
supabase functions deploy vnpay-create-payment
supabase functions deploy vnpay-ipn
supabase functions deploy vnpay-return
supabase functions deploy ai-dj
```

5. Trong cấu hình merchant VNPay Sandbox, đặt IPN URL thành
   `https://YOUR_PROJECT_REF.supabase.co/functions/v1/vnpay-ipn`.
6. Cài lại app sau khi build. Chọn **Nâng cấp** trong trang Cá nhân hoặc mở AI
   DJ, thanh toán bằng phương thức thử nghiệm VNPay, rồi quay lại app. Nếu IPN
   đến chậm, chọn **Kiểm tra trạng thái**.

## Import và cập nhật catalog nhạc

Admin chạy script import trên máy tin cậy. Trước tiên, tạo CSV mẫu từ thư mục
MP3. Script sẽ tự điền các trường đọc được từ tag ID3:

```powershell
node supabase/scripts/import_tracks.mjs --template '..\music_data' 'supabase\music_metadata.csv'
```

Lệnh tạo mẫu sẽ không ghi đè CSV đã tồn tại, giúp tránh mất phần metadata bạn đã
chỉnh sửa.

Chỉnh sửa CSV và dùng chính xác tên file MP3 để ghép mỗi dòng metadata với file
âm thanh. Các cột gồm `filename`, `title`, `artist`, `album`,
`duration_seconds`, `genres` và `cover_filename` (không bắt buộc). Phân tách
nhiều thể loại bằng dấu chấm phẩy. Dùng `genres` cho một hoặc nhiều thể loại;
ví dụ `Rap Việt;Hip-Hop;R&B`. Các nhãn này được lưu thành mảng trong cột
`genres` và các mã tương ứng được liên kết trong `song_genres`. Tên thể loại
hiển thị trong danh sách/thẻ bài hát và có thể dùng để lọc ở Home hoặc tìm kiếm.
Đường dẫn ảnh bìa được tính tương đối từ thư mục nhạc. Cột `tags` cũ vẫn được
đọc để tương thích với CSV cũ.
Giá trị trong CSV được ưu tiên hơn tag ID3; ô CSV để trống sẽ dùng metadata ID3
nếu có. Với bản ghi đã tồn tại, các trường vẫn thiếu sẽ được giữ nguyên trong
Supabase.

Để bổ sung hoặc sửa thể loại cho bài đã import, điền các nhãn phân cách bằng
dấu chấm phẩy ở cột `genres`, rồi chạy lại lệnh import. Script sẽ cập nhật các
mã liên kết thể loại và metadata theo `filename` mà không tải lại MP3 nếu nội
dung audio không đổi.

Sau khi rà soát CSV, chạy lệnh import. Chỉ giữ khóa service-role trong biến môi
trường của terminal; không đưa khóa này vào Flutter hoặc commit vào repository.

```powershell
$env:SUPABASE_URL = 'https://YOUR_PROJECT.supabase.co'
$env:SUPABASE_SERVICE_ROLE_KEY = 'YOUR_SERVICE_ROLE_KEY'
node supabase/scripts/import_tracks.mjs '..\music_data' 'supabase\music_metadata.csv'
Remove-Item Env:SUPABASE_SERVICE_ROLE_KEY
```

Script tải audio lên bucket riêng tư `tracks` và ảnh bìa lên bucket công khai
`covers`. Khi chạy lại, script cập nhật audio và metadata của các file có tên
trùng khớp, đồng thời thêm các file MP3 mới. Nếu audio của bài đã có trên
Storage và hash không đổi, script bỏ qua tải lại audio. Lỗi mạng, giới hạn tốc
độ và lỗi máy chủ tạm thời sẽ được thử lại tối đa tám lần. Nếu kết nối vẫn thất
bại, chạy lại đúng lệnh import; các bài đã xong không bị nhân đôi. Ứng dụng
client chỉ có quyền đọc các bản ghi catalog.

Thư mục `music_data` nằm cạnh thư mục project và hiện có 43 file MP3. CSV mẫu
được tạo sẵn tại `supabase/music_metadata.csv`; hãy kiểm tra lại dữ liệu lấy từ
ID3 và điền các trường còn thiếu trước khi import.

### Lỗi quyền truy cập khi import

Nếu import báo `row-level security policy` hoặc `AccessDenied`, hãy kiểm tra
`SUPABASE_SERVICE_ROLE_KEY`. Dùng Secret key (`sb_secret_...`) trong mục API Keys
hoặc khóa `service_role` legacy của đúng project; không dùng Publishable/anon key
cho Flutter. Script gửi Secret key theo header `apikey` và chỉ gửi Bearer header
cho khóa legacy dạng JWT. Không mở policy ghi cho người dùng đã đăng nhập để xử
lý lỗi này. Script sẽ nêu thao tác bị từ chối, ví dụ tải audio hay cập nhật
catalog.

Nếu gặp lỗi `23502` với cột `title` hoặc `artist`, cập nhật script lên bản mới
rồi chạy lại cùng lệnh import. Script sẽ lấy giá trị từ CSV, ID3, bản ghi catalog
đã có, hoặc dùng tên file/`Chưa rõ nghệ sĩ` làm giá trị dự phòng.

Nếu script báo `could not reach Supabase`/`fetch failed`, kiểm tra
`SUPABASE_URL` có dạng `https://<project-ref>.supabase.co` (không phải URL của
Dashboard) và máy có thể kết nối HTTPS tới host đó. Thông báo mới của script sẽ
cho biết thao tác và mã lỗi mạng nếu Node cung cấp.
