# Kế hoạch việc cần làm tiếp theo cho MyTube

Danh sách này được lập từ [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) và cấu trúc mã nguồn hiện có, với phạm vi đã chốt là **đồ án/demo học tập**, ưu tiên ứng dụng trình chiếu trên **Android**, và **chưa ưu tiên AI**. Các file MP4 đã được chuyển thành MP3 và đã có project Supabase.

## Quy ước theo dõi

- Đánh dấu `[x]` chỉ sau khi hạng mục tương ứng đã được thực hiện và kiểm tra.
- Các quyết định/yêu cầu đã được người dùng xác nhận được ghi ở mục **Yêu cầu đã chốt**, không tính là công việc hoàn thành.
- Sau mỗi bước triển khai, cập nhật checkbox ngay trong file này để theo dõi tiến độ.

## Yêu cầu đã chốt

- Người dùng tự đăng ký bằng email và mật khẩu; cần đăng nhập mới nghe nhạc.
- Catalog nhạc dùng chung cho các tài khoản. Playlist, yêu thích và lịch sử nghe lưu riêng theo tài khoản.
- Hỗ trợ nhiều điện thoại Android; phát trực tuyến khi có Internet và lưu audio offline trên thiết bị.
- Các file MP4 đã được đổi sang MP3. Người dùng có quyền lưu trữ và stream các bài nhạc.
- Metadata MP3 có một phần; dùng CSV để bổ sung metadata còn thiếu.
- Cần chạy import nhiều lần để thêm bài mới; sẽ có tài khoản admin phụ trách catalog.
- Admin chạy script import riêng trên máy tin cậy; service-role key không được đưa vào ứng dụng Flutter hoặc commit vào repository.
- Cần xác minh email và chức năng đặt lại mật khẩu.
- Khi import lại bài đã có, cho phép cập nhật metadata từ CSV.
- CSV ghép với MP3 bằng tên file chính xác ở cột `filename`; không cần đổi tên các file nhạc.
- Giữ giao diện hiện tại; AI chưa phải ưu tiên.
- Tinh gọn trang Cá nhân: bỏ thống kê số bài hát và nghệ sĩ; cộng thời gian audio thực sự phát và đồng bộ tổng thời lượng lên Supabase.
- Tải offline: hỗ trợ tải bài đơn hoặc toàn playlist, giới hạn mặc định 1 GB, hiển thị dung lượng và cho xóa từng bài/toàn bộ.
- Hẹn giờ ngủ: hỗ trợ hẹn theo khoảng thời gian hoặc hết bài hiện tại; giảm âm lượng từ từ trước khi dừng.
- Giao diện: chọn Sáng, Tối hoặc Theo hệ thống; lưu lựa chọn trên thiết bị.

## Ưu tiên 1: Làm demo Android chạy ổn định

- [x] Đưa toàn bộ MP3 trong `..\music_data` lên catalog/storage Supabase dùng chung để mọi tài khoản đã đăng nhập đều thấy cùng một kho nhạc.
- [x] Xác nhận cấu hình Supabase cho demo: đăng nhập email/password, catalog có bài hát, Storage stream audio được và có tài khoản thử nghiệm.
- [x] Đồng bộ danh sách yêu thích từ Supabase sau khi đăng nhập và xóa/reset trạng thái người dùng khi đăng xuất hoặc đổi tài khoản; kiểm tra logic reset trong unit test.
- [x] Làm mới signed URL từ catalog mỗi lần bắt đầu phát, kể cả bài đã nằm lâu trong queue; analyzer thông qua.
- [x] Hiển thị trạng thái tải/lỗi và thao tác thử lại khi audio/storage/network gặp lỗi; analyzer thông qua.
- [x] Kiểm tra queue rỗng, next/previous, seek giới hạn, shuffle và repeat bằng unit test.
- [ ] Kiểm tra đăng nhập, phát nhạc, mini-player, playlist và đăng xuất trên thiết bị/emulator Android dùng để trình diễn.
- [x] Chỉ hoàn thiện phát nền và notification nếu đây là nội dung cần trình bày trong demo; xác minh quyền và metadata trên Android mục tiêu.

## Ưu tiên 2: Chuẩn bị dữ liệu trình diễn

- [x] Xác nhận thư mục nguồn `..\music_data` hiện có 43 file MP3; đây là vị trí nằm cạnh thư mục project.
- [x] Cập nhật script import để sinh CSV mẫu từ ID3, ghép theo tên file, nhận CSV bổ sung metadata, tải cover, và upsert theo `source_filename`; kiểm tra cú pháp bằng `node --check`.
- [x] Thêm retry tối đa 8 lần cho lỗi mạng/429/5xx và resume an toàn bằng cách bỏ qua audio đã upload có cùng hash; kiểm tra cú pháp bằng `node --check`.
- [x] Sửa upsert để luôn điền `title`/`artist` bắt buộc và giữ metadata cũ khi dữ liệu CSV/ID3 bị trống; kiểm tra cú pháp.
- [x] Thêm migration tạo unique index cho `source_filename` và cập nhật hướng dẫn import trong `supabase/README.md`.
- [x] Tạo CSV khởi đầu `supabase/music_metadata.csv` từ tag ID3 của 43 MP3.
- [x] Áp dụng migration `202611070002_song_source_filename.sql`, `202611080001_normalize_song_genres.sql` và `202611080002_seed_music_genres.sql` lên Supabase theo thứ tự.
- [x] Rà soát/sửa thông tin trong CSV, chạy import trên 43 MP3 và xác nhận catalog/Storage đọc được từ app.
- [x] Rà soát metadata catalog sau import: thời lượng, album, cover và thể loại; bổ sung CSV cho những trường cần thiết còn thiếu.
- [x] Tìm kiếm bao gồm tên bài, nghệ sĩ, album và thể loại. Catalog hiện có 43 bài nên tiếp tục lọc ở client; chuyển sang truy vấn/phân trang backend khi catalog tăng đáng kể.
- [x] Thêm/xóa bài giữ thứ tự hiển thị, cập nhật `updated_at`, và xử lý bài trùng; thao tác lỗi mạng được giao diện báo lỗi.
- [x] Xác định các khu vực nào cần dữ liệu thật thay cho `MusicData` mẫu: danh sách bài hát, thể loại và playlist cá nhân đọc từ Supabase; thể loại chỉ dùng cấu hình màu/icon tĩnh; chưa có màn khám phá nghệ sĩ hoặc playlist biên tập dùng chung.

## AI DJ: Gemini

- [x] Chuyển hội thoại AI DJ sang Gemini qua Supabase Edge Function; key không nằm trong ứng dụng.
- [x] Giới hạn câu trả lời vào âm nhạc, ràng buộc gợi ý vào catalog, cá nhân hóa từ bài thích/lịch sử theo RLS.
- [x] Cho phép chỉnh tên và danh sách bài trong bản nháp playlist trước khi người dùng xác nhận lưu.
- [ ] Tạo Gemini API key, lưu vào Supabase secrets và deploy `ai-dj` theo `supabase/README.md`.

## Ưu tiên 4: Hoàn thiện báo cáo và gói demo

- [x] Rà soát migration trong repository: client chỉ đọc catalog/stream audio; playlist, liked và lịch sử giới hạn theo `auth.uid()`; client không được ghi catalog; service-role key chỉ dùng trong script admin qua biến môi trường.
- [x] Xác minh trên project Supabase thật bằng hai tài khoản: mỗi tài khoản chỉ thấy playlist của mình; cả hai đọc được catalog chung và stream nhạc.
- [x] Bổ sung README gốc với yêu cầu môi trường, cấu hình Supabase, chạy ứng dụng và nhập nhạc.
- [x] Tập trung cấu hình, quyền, audio và hướng dẫn cài đặt cho Android; chưa mở rộng sang iOS/Web.
- [x] Bổ sung unit/widget test cho validation đăng nhập, smoke test màn đăng nhập, reset liked state, queue/seek/shuffle/repeat và trạng thái lỗi playback.
- [ ] Bổ sung kiểm thử tích hợp cho catalog, liked, playlist và lỗi mạng với Supabase; hiện chưa có mock repository/session để xác minh các luồng này tự động.
- [x] Tạo kịch bản demo dùng tài khoản email đã xác minh và catalog 43 bài đã import; xem `DEMO_GUIDE.md`. Ảnh chụp màn hình vẫn cần chụp trên thiết bị/emulator Android mục tiêu.
- [x] Chạy `flutter analyze` và `flutter test` thành công; build APK release thành công tại `build/app/outputs/flutter-apk/app-release.apk` (52,9 MB).
- [ ] Tinh gọn trang Cá nhân và đồng bộ tổng thời gian phát thực tế theo tài khoản; cần áp dụng migration `202611080003_listening_time.sql` trên Supabase.
- [x] Bỏ cài đặt bộ chỉnh âm/chất lượng truyền phát chưa hỗ trợ.
- [x] Tải bài hoặc playlist offline; quản lý hạn mức 1 GB, dung lượng đã dùng và xóa tải xuống.
- [x] Hẹn giờ theo khoảng thời gian hoặc hết bài hiện tại, có giảm âm lượng từ từ.
- [x] Chọn giao diện Sáng/Tối/Theo hệ thống và lưu lựa chọn trên thiết bị.

## Thứ tự triển khai gợi ý

1. Chuẩn bị project Supabase và tài khoản/dữ liệu đủ để chạy demo.
2. Ổn định đăng nhập, liked state và playback trên Android.
3. Hoàn thiện CSV metadata và import catalog chung lên Supabase.
4. Hoàn thiện các thao tác playlist và trạng thái lỗi có thể gặp khi demo.
5. Cập nhật README, kiểm tra Android và tạo APK trình diễn.

## Định dạng CSV

Mỗi dòng mô tả một bài hát; `filename` phải khớp chính xác tên MP3 trong thư mục. Script tạo các cột `filename`, `title`, `artist`, `album`, `duration_seconds`, `genres`, `cover_filename`. `genres` phân tách bằng dấu chấm phẩy; `cover_filename` là đường dẫn ảnh tương đối bên trong thư mục nhạc. Ví dụ:

```csv
filename,title,artist,album,genres
track_01.mp3,Ca khúc mẫu,Nghệ sĩ mẫu,Album mẫu,"chill;vietnamese"
```

Không cần đổi tên file. Giá trị có trong CSV được ưu tiên hơn ID3; ô trống dùng metadata ID3 nếu có. Nếu một trường vẫn trống trên bản ghi đã có, script giữ nguyên giá trị Supabase.

## Ghi chú phạm vi

Tài liệu này đề xuất việc tiếp theo, không khẳng định các hạng mục đã được xác minh trên project Supabase đang chạy. Trước buổi trình chiếu cần đối chiếu schema, policy, quyền Storage và cấu hình thực tế của Supabase với cách truy cập catalog mà bạn chọn.

## Việc còn cần xác minh ngoài workspace

- Đăng nhập, phát stream, mini-player, playlist và đăng xuất trên thiết bị/emulator Android; hiện ADB không phát hiện thiết bị kết nối.
- RLS/Storage đã được người dùng xác nhận trên project Supabase thật: hai tài khoản không thấy playlist của nhau, cùng đọc catalog và stream nhạc.
- Tích hợp repository với Supabase thật và APK release sau khi chạy analyzer/test thành công.
