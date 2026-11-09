# Test cases MyTube Android release

## Thông tin chạy test

| Mục | Giá trị |
| --- | --- |
| Bản app / version |  |
| Thiết bị / Android |  |
| Supabase project |  |
| Tài khoản A / B | Hai tài khoản test đã xác minh email; không ghi mật khẩu tại đây |
| Kết quả | Điền `Pass`, `Fail` hoặc `Blocked`; ghi build, ngày và lỗi nếu cần |

Chạy trên APK release đã cài trên thiết bị Android mục tiêu. Dùng mạng ổn định,
catalog có bài hoạt động, audio truy cập được và hai tài khoản thử nghiệm. Các
test Premium cần VNPay Sandbox; các test AI cần Edge Function `ai-dj`, Gemini
secret và tài khoản Premium hoạt động. Không dùng dữ liệu hoặc phương thức thanh
toán thật.

## Cài đặt và xác thực

| ID | Ưu tiên | Tiền điều kiện | Bước thực hiện | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- | --- | --- |
| REL-001 | P0 | APK release hợp lệ | Cài mới APK, mở app | App mở không crash; hiển thị màn đăng nhập hoặc màn chính nếu có session hợp lệ |  |
| REL-002 | P0 | Đã đăng xuất | Để trống email/mật khẩu, nhấn Đăng nhập | Báo lỗi validation; không gửi yêu cầu đăng nhập |  |
| REL-003 | P1 | Đã đăng xuất | Nhập email sai định dạng và mật khẩu ngắn, nhấn Đăng nhập | Hiện lỗi cho từng trường; không crash |  |
| REL-004 | P0 | Email test chưa đăng ký, có thể nhận email | Đăng ký bằng email hợp lệ và mật khẩu đạt yêu cầu; mở email xác minh | Tài khoản được tạo; app yêu cầu xác minh nếu cấu hình bật; link xác minh mở lại MyTube |  |
| REL-005 | P0 | Có tài khoản đã xác minh | Đăng nhập đúng thông tin, đóng/mở lại app | Đăng nhập thành công; session còn hiệu lực sau khi mở lại |  |
| REL-006 | P1 | Có tài khoản đã xác minh | Đăng nhập sai mật khẩu | App báo thất bại rõ ràng; không tạo session |  |
| REL-007 | P1 | Có tài khoản email hợp lệ | Chọn Quên mật khẩu, gửi email, mở link reset | App gửi yêu cầu; link mở luồng đặt lại mật khẩu; mật khẩu mới đăng nhập được |  |

## Catalog, tìm kiếm và phát nhạc

| ID | Ưu tiên | Tiền điều kiện | Bước thực hiện | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- | --- | --- |
| REL-008 | P0 | Đăng nhập, có mạng, catalog đã import | Mở Khám phá và cuộn danh sách | Bài hoạt động hiển thị; title, artist, cover và thời lượng không làm vỡ layout |  |
| REL-009 | P1 | Catalog có bài thuộc nhiều thể loại | Mở Tìm kiếm, nhập một phần tên bài/nghệ sĩ/album | Kết quả phù hợp với từ khóa; xóa từ khóa thì danh sách trở lại |  |
| REL-010 | P1 | Catalog có thể loại đã gán | Chọn một thể loại | Chỉ hiện bài thuộc thể loại; bài không có thể loại đó không xuất hiện |  |
| REL-011 | P0 | Có bài stream được | Phát một bài từ Khám phá | Audio bắt đầu; mini-player hiển thị đúng bài và trạng thái phát |  |
| REL-012 | P0 | Đang phát | Mở mini-player; tạm dừng, phát tiếp, tua tiến/lùi | Trạng thái và vị trí phát cập nhật đúng; tua không vượt ngoài đầu/cuối bài |  |
| REL-013 | P1 | Có ít nhất hai bài trong queue | Dùng Tiếp theo/Trước đó; bật/tắt shuffle và repeat | Bài hiện tại đổi theo queue; shuffle/repeat có trạng thái và hành vi tương ứng |  |
| REL-014 | P0 | Audio đang phát | Thu nhỏ app hoặc khóa màn hình; điều khiển từ notification; quay lại app | Phát nền tiếp tục; notification hiển thị metadata và điều khiển phản ánh đúng trạng thái |  |
| REL-015 | P1 | Có mạng chập chờn hoặc audio URL lỗi | Phát bài lỗi, thử lại sau khi mạng ổn định | App hiển thị trạng thái lỗi và nút thử lại; thử lại thành công không nhân đôi queue |  |

## Thư viện và dữ liệu tài khoản

| ID | Ưu tiên | Tiền điều kiện | Bước thực hiện | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- | --- | --- |
| REL-016 | P0 | Đăng nhập tài khoản A, đang phát bài | Thích/bỏ thích một bài; mở Thư viện > Đã thích | Thay đổi được lưu và phản ánh trong danh sách; trạng thái còn sau khi khởi động lại |  |
| REL-017 | P0 | Tài khoản A và B; A đã thích bài | Đăng xuất A, đăng nhập B | B không thấy trạng thái yêu thích của A; thao tác của B không thay đổi dữ liệu A |  |
| REL-018 | P0 | Đăng nhập tài khoản A | Tạo playlist, thêm hai bài, phát playlist | Playlist xuất hiện trong thư viện; bài và thứ tự đúng; phát playlist tạo queue phù hợp |  |
| REL-019 | P1 | Có playlist với nhiều bài | Đổi tên playlist; xóa một bài và thêm lại | Tên và danh sách cập nhật; thao tác xóa/thêm phản ánh sau khi tải lại |  |
| REL-020 | P1 | Playlist trống và playlist có bài | Thử phát playlist trống; xóa playlist có xác nhận | Playlist trống không gây crash; hủy xác nhận giữ playlist; xác nhận xóa loại bỏ playlist |  |
| REL-021 | P0 | Hai tài khoản A và B | Tạo playlist ở A; đăng nhập B và mở Thư viện | Playlist của A không xuất hiện ở B; catalog chung vẫn truy cập được |  |
| REL-022 | P1 | Đã nghe một phần bài | Mở Lịch sử nghe | Bài đã phát xuất hiện với thông tin đúng; không hiển thị lịch sử tài khoản khác |  |
| REL-037 | P0 | Migration `202611090001_profile_avatar_sync.sql` đã áp dụng; hai thiết bị online cùng tài khoản | Giữ Home hoặc Cá nhân mở trên thiết bị B; đổi avatar và lưu trên thiết bị A | Avatar cập nhật trên B mà không cần đăng xuất/đăng nhập lại; mở Home và Cá nhân đều thấy ảnh mới |  |

## Tải offline, hẹn giờ và giao diện

| ID | Ưu tiên | Tiền điều kiện | Bước thực hiện | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- | --- | --- |
| REL-023 | P0 | Có mạng, bài stream được | Tải một bài về thiết bị | Tải hoàn tất; bài xuất hiện trong Đã tải về; dung lượng sử dụng tăng hợp lý |  |
| REL-024 | P0 | Đã tải bài thành công | Bật chế độ máy bay, phát bài đã tải | Bài phát từ file cục bộ; không cần signed URL hoặc kết nối mạng |  |
| REL-025 | P1 | Có bài đã tải | Xóa một bài rồi xóa toàn bộ lượt tải | File không còn trong danh sách; dung lượng giảm/cập nhật; app không còn phát file đã xóa |  |
| REL-026 | P1 | Có đủ dữ liệu để tiếp cận hạn mức 1 GB hoặc dùng môi trường kiểm thử | Thử tải file khiến tổng vượt 1 GB | App từ chối tải vượt hạn mức, báo lỗi; file dở dang không được giữ và không tính vào danh sách |  |
| REL-027 | P1 | Đang phát bài đủ dài | Đặt hẹn giờ theo thời lượng; mở lại bảng hẹn giờ | Trạng thái hẹn được hiển thị; khi hết giờ âm lượng giảm dần rồi phát dừng |  |
| REL-028 | P1 | Bài hiện tại còn đủ thời gian | Chọn dừng sau bài hiện tại | Bài hiện tại kết thúc với hiệu ứng giảm âm lượng rồi dừng, không tự phát bài tiếp |  |
| REL-029 | P2 | Đang có hoặc không có bài phát | Đổi giao diện Sáng/Tối/Theo hệ thống; đóng mở app | Giao diện đổi đúng lựa chọn và lựa chọn được lưu qua lần mở sau |  |

## Premium và AI DJ (cần môi trường tích hợp)

| ID | Ưu tiên | Tiền điều kiện | Bước thực hiện | Kết quả mong đợi | Kết quả |
| --- | --- | --- | --- | --- | --- |
| REL-030 | P1 | Tài khoản chưa Premium | Mở trang Premium | Hiển thị giá 10.000đ/30 ngày và nút thanh toán VNPay; không cấp AI DJ trước khi kích hoạt |  |
| REL-031 | P1 | VNPay Sandbox và callback hoạt động | Bắt đầu thanh toán; hoàn tất giao dịch thành công; quay lại app | Kết quả được kiểm tra từ backend; Premium hoạt động đúng tài khoản và ngày hết hạn hiển thị |  |
| REL-032 | P1 | VNPay Sandbox | Thử hủy giao dịch hoặc trả thất bại; quay lại app | Không cấp Premium; app không hiển thị thanh toán thành công; cho phép kiểm tra lại trạng thái |  |
| REL-033 | P1 | Tài khoản Premium, AI DJ đã deploy | Gửi yêu cầu gợi ý âm nhạc | Trả lời liên quan đến nhạc; bài được gợi ý nằm trong catalog |  |
| REL-034 | P1 | Tài khoản Premium, AI DJ đã deploy | Yêu cầu tạo playlist; đổi tên/bỏ bài trong bản nháp rồi lưu | Bản nháp chỉnh được; chỉ playlist đã xác nhận mới lưu vào Thư viện với đúng tên và danh sách |  |
| REL-035 | P1 | Tài khoản Premium | Gửi yêu cầu ngoài chủ đề âm nhạc | AI từ chối theo phạm vi sản phẩm; app vẫn nhận input tiếp theo, không treo |  |
| REL-036 | P1 | AI Function tạm không khả dụng hoặc mất mạng | Gửi tin nhắn AI | App báo lỗi/kết nối không thành công; cho phép thử lại và không tạo playlist dở dang |  |

## Bàn giao kết quả

Ghi `Pass`, `Fail` hoặc `Blocked` cho từng ID đã chạy. Với lỗi, lưu bước tái
hiện, kết quả thực tế, ảnh/video nếu phù hợp, thời điểm, version APK và model
thiết bị; không đính kèm mật khẩu, OTP, khóa API hoặc thông tin thanh toán.

Test tích hợp cần project Supabase staging riêng và VNPay Sandbox. Không chạy
các thao tác thanh toán hoặc dữ liệu phá hủy trên tài khoản production để xác
nhận các case này.
