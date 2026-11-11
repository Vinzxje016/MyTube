# KỊCH BẢN & LỜI THOẠI QUAY VIDEO BÁO CÁO ĐỒ ÁN CUỐI KỲ
**Học phần:** Lập trình trên thiết bị di động (CMP177)  
**Tên đề tài:** Ứng dụng nghe nhạc thông minh MyTube Music trên Flutter  
**Kho lưu trữ Git:** [https://github.com/Vinzxje016/MyTube](https://github.com/Vinzxje016/MyTube)  
**Nhóm thực hiện:** Nhóm số [Số nhóm]  
- Thành viên 1: [Họ tên thành viên 1] - MSSV: [Mã số SV 1]  
- Thành viên 2: [Họ tên thành viên 2] - MSSV: [Mã số SV 2]  

---

## I. HƯỚNG DẪN QUY CHUẨN THỰC HIỆN (THEO VĂN BẢN CMP177)

1. **Thời lượng video:** Khống chế từ **8 đến 9 phút** (Quy định bắt buộc: **Tối đa 10 phút**; video dài quá 10 phút sẽ bị trừ điểm theo barem).
2. **Camera:** Tất cả thành viên trong nhóm **bắt buộc phải xuất hiện trên camera** trong suốt toàn bộ quá trình báo cáo.
3. **Môi trường & tác phong:** Trang phục lịch sự, đủ ánh sáng, âm thanh thu rõ ràng, tránh tiếng ồn.
4. **Thao tác thực tế:** Thao tác trực tiếp trên ứng dụng (máy ảo Android Emulator hoặc điện thoại thật), không dùng ảnh chụp màn hình thay thế.
5. **Bảo mật thông tin:** Tuyệt đối không để lộ mật khẩu, API key cá nhân, token bí mật hay số thẻ ngân hàng thật trong video.

---

## II. BẢNG PHÂN BỔ THỜI LƯỢNG CHI TIẾT

| Thời gian | Nội dung trình bày | Thao tác trên màn hình demo |
| :--- | :--- | :--- |
| **00:00 – 00:50** | **Phần 1:** Chào hỏi, giới thiệu nhóm & đề tài | Bật camera tất cả thành viên, slide cover MyTube |
| **00:50 – 01:50** | **Phần 2:** Giới thiệu công nghệ (Flutter + Supabase) | Mở app MyTube, chiếu sơ đồ kiến trúc |
| **01:50 – 02:40** | **Module 1:** Đăng nhập AuthGate & Màn hình Khám phá | Đăng nhập tài khoản demo, lướt giao diện Home |
| **02:40 – 03:50** | **Module 2:** Trình phát nhạc Now Playing & Phát nền | Phát nhạc, tua thời gian, lời bài hát, Notification |
| **03:50 – 04:50** | **Module 3:** Tìm kiếm thể loại & Thư viện cá nhân | Lọc thể loại, thả tim bài hát, tạo Playlist (RLS) |
| **04:50 – 05:50** | **Module 4:** Nghe nhạc Ngoại tuyến (Offline Mode) | Tải bài, bật Chế độ máy bay, phát nhạc offline |
| **05:50 – 07:15** | **Module 5:** Trợ lý âm nhạc thông minh AI DJ | Chat hỏi AI DJ, nhận gợi ý catalog & tạo playlist |
| **07:15 – 08:15** | **Module 6:** Nâng cấp gói Premium VNPay & Tiện ích | Thanh toán VNPay Sandbox, hẹn giờ ngủ, đổi Theme |
| **08:15 – 08:45** | **Phần 4:** Tổng kết, đối chiếu Git & Lời cảm ơn | Chiếu trang GitHub repository, chào giảng viên |

---

## III. LỜI THOẠI CHI TIẾT TỪNG PHÂN CẢNH (VERBATIM SCRIPT)

### PHẦN 1: MỞ ĐẦU VÀ GIỚI THIỆU NHÓM (00:00 – 00:50)
* **Hình ảnh:** Màn hình Google Meet/Zoom hiển thị camera các thành viên và slide tiêu đề.
* **Lời thoại [Người nói 1]:**
> "Kính chào Thầy/Cô phụ trách học phần Lập trình trên thiết bị di động (mã học phần CMP177).  
> Nhóm chúng em là **Nhóm số [Số nhóm]**. Hôm nay, nhóm em xin phép được trình bày video báo cáo và demo đồ án cuối kỳ với đề tài: **Xây dựng ứng dụng nghe nhạc thông minh MyTube Music trên nền tảng Flutter**.  
>  
> Nhóm chúng em gồm có [Số lượng] thành viên có mặt đầy đủ trên camera:  
> 1. Em tên là **[Họ và tên thành viên 1]**, MSSV: **[Mã số sinh viên 1]** - đảm nhiệm [vai trò: Thiết kế UI/UX và logic Client Flutter].  
> 2. Thành viên thứ hai là bạn **[Họ và tên thành viên 2]**, MSSV: **[Mã số sinh viên 2]** - đảm nhiệm [vai trò: Xây dựng Backend Supabase, API thanh toán và AI Edge Functions].  
>  
> Sau đây, nhóm em xin bắt đầu phần giới thiệu tổng quan về đề tài và công nghệ sử dụng."

---

### PHẦN 2: GIỚI THIỆU ĐỀ TÀI VÀ CÔNG NGHỆ (00:50 – 01:50)
* **Hình ảnh:** Bắt đầu chia sẻ màn hình điện thoại/máy ảo Android đang mở ứng dụng.
* **Lời thoại [Người nói 1 hoặc 2]:**
> "Về tính cấp thiết của đề tài: Âm nhạc là nhu cầu thiết yếu hàng ngày, nhưng đa số các ứng dụng hiện nay đòi hỏi kết nối mạng liên tục và khả năng gợi ý theo ngữ cảnh còn hạn chế. Nhóm đã phát triển MyTube Music nhằm mang lại trải nghiệm nghe nhạc mượt mà, hỗ trợ nghe ngoại tuyến và đặc biệt là tích hợp trợ lý AI để hiểu và gợi ý bài hát theo cảm xúc của người dùng.  
>  
> Về các công nghệ chủ chốt mà nhóm ứng dụng thực tế trong đồ án:  
> - **Frontend Mobile:** Nhóm sử dụng công nghệ cốt lõi bắt buộc là **Flutter (Dart)**, thiết kế theo phong cách Dark Glassmorphic hiện đại, kết hợp `just_audio` và `audio_service` để chạy tiến trình phát nhạc nền background service trên Android.  
> - **Backend & Cơ sở dữ liệu:** Triển khai trên **Supabase** với hệ quản trị **PostgreSQL**, quản lý danh mục bài hát, xác thực người dùng và bảo mật dữ liệu cá nhân bằng cơ chế **Row Level Security (RLS)**.  
> - **Tính năng thông minh & Mở rộng:** Tích hợp **Supabase Edge Functions** kết hợp **Google Gemini AI** cho tính năng AI DJ, cùng cổng thanh toán **VNPay Sandbox** để nâng cấp gói thành viên Premium.  
>  
> Sau đây, nhóm em xin bước vào phần demo trực tiếp các chức năng chính của ứng dụng MyTube Music."

---

### PHẦN 3: DEMO CÁC CHỨC NĂNG CHÍNH (01:50 – 08:15)

#### 1. Module Xác thực & Màn hình Khám phá (01:50 – 02:40)
* **Thao tác màn hình:** Mở app $\rightarrow$ Thấy AuthGate $\rightarrow$ Đăng nhập bằng tài khoản email demo đã lưu $\rightarrow$ Chuyển vào HomeScreen $\rightarrow$ Cuộn nhẹ qua các mục Nghe Gần Đây, Tuyển tập thịnh hành.
* **Lời thoại:**
> "Đầu tiên là **Module Xác thực và Màn hình Khám phá**. Ứng dụng tích hợp AuthGate thông qua Supabase Auth. Khi đăng nhập thành công bằng email, người dùng sẽ được đưa trực tiếp vào màn hình Khám phá.  
> Tại đây, hệ thống chào mừng người dùng theo thời gian thực. Phía trên là mục 'Nghe Gần Đây' dạng lưới hai cột giúp bật nhanh bài hát quen thuộc chỉ với 1 chạm. Phía dưới là các carousel tuyển tập thịnh hành và nghệ sĩ nổi bật được đồng bộ từ catalog đám mây."

#### 2. Module Trình phát nhạc toàn diện & Phát nhạc nền (02:40 – 03:50)
* **Thao tác màn hình:** Chạm 1 bài hát $\rightarrow$ Mini-player hiện lên với sóng nhạc Equalizer $\rightarrow$ Bấm mở NowPlayingScreen $\rightarrow$ Tua slider thời gian $\rightarrow$ Chạm nút xem Lời bài hát Karaoke $\rightarrow$ Thu nhỏ app ra màn hình Home của điện thoại $\rightarrow$ Kéo thanh thông báo Notification xuống để thấy audio control.
* **Lời thoại:**
> "Tiếp theo là **Module Phát nhạc (Audio Playback)** - chức năng cốt lõi của ứng dụng. Khi chạm vào bất kỳ bài hát nào, thanh Mini-player phía dưới đáy sẽ lập tức kích hoạt với hiệu ứng sóng nhạc Equalizer động.  
> Khi mở màn hình phát nhạc toàn màn hình (Now Playing), giao diện sử dụng hiệu ứng Ambient Glow tự động đổi màu tỏa sáng theo tông màu của bìa đĩa. Tại đây, người dùng có thể kéo tua vị trí bài hát, bật ngẫu nhiên Shuffle, lặp lại bài hát, và đặc biệt là chuyển đổi nhanh sang màn hình hiển thị lời bài hát đồng bộ.  
> Nhờ tích hợp thư viện `audio_service`, khi em thu nhỏ ứng dụng hoặc khóa màn hình điện thoại, bài hát vẫn tiếp tục phát trong nền và người dùng có thể tạm dừng, chuyển bài trực tiếp từ thanh **Notification của Android** mà không cần mở lại app."

#### 3. Module Tìm kiếm & Thư viện cá nhân (03:50 – 04:50)
* **Thao tác màn hình:** Chuyển sang tab Tìm kiếm $\rightarrow$ Gõ tìm theo tên bài hoặc nghệ sĩ $\rightarrow$ Bấm vào thẻ thể loại V-Pop $\rightarrow$ Thả tim một bài hát $\rightarrow$ Chuyển sang tab Thư viện $\rightarrow$ Cho thấy mục Bài hát đã thích $\rightarrow$ Bấm dấu (+) Tạo Playlist mới 'Nhạc Tập Trung' $\rightarrow$ Thêm bài hát vào.
* **Lời thoại:**
> "Module thứ ba là **Tìm kiếm và Quản lý Thư viện**. Ở tab Tìm kiếm, ứng dụng hỗ trợ lọc nhanh theo tên bài hát hoặc nghệ sĩ, đồng thời phân chia các thể loại như V-Pop, Lo-Fi, Hip-hop dưới dạng các thẻ màu gradient sinh động.  
> Khi người dùng nhấn biểu tượng yêu thích, bài hát sẽ tự động đồng bộ vào mục 'Bài hát đã thích' trong Thư viện cá nhân. Người dùng cũng có thể tạo mới các danh sách phát (Playlist), tùy chỉnh tên và thêm bài hát theo ý thích. Nhờ cơ chế **Row Level Security (RLS)** của Supabase, danh sách phát và bài hát yêu thích được mã hóa và bảo mật riêng tư tuyệt đối cho từng tài khoản, không bị trùng lặp giữa các người dùng."

#### 4. Module Nghe nhạc Ngoại tuyến không cần mạng (04:50 – 05:50)
* **Thao tác màn hình:** Mở 1 bài hát $\rightarrow$ Bấm Tải bài hát về máy $\rightarrow$ Chuyển qua Thư viện chọn bộ lọc 'Đã tải về' $\rightarrow$ Vuốt thanh trạng thái Android bật **Chế độ máy bay (Airplane Mode)** $\rightarrow$ Bấm phát bài hát offline $\rightarrow$ Bài hát phát mượt mà.
* **Lời thoại:**
> "Một tính năng đặc trưng và rất thiết thực của MyTube là **Khả năng nghe nhạc Ngoại tuyến (Offline Mode)**.  
> Người dùng có thể tải bài hát hoặc cả danh sách phát về lưu trữ trên bộ nhớ máy thông qua dịch vụ `OfflineMusicService`. Như Thầy/Cô đang thấy trên màn hình, sau khi bài hát đã được tải về máy, em sẽ **bật Chế độ máy bay** để ngắt toàn bộ kết nối Wi-Fi và mạng di động 4G.  
> Khi truy cập mục 'Đã tải về', ứng dụng vẫn nhận diện được dữ liệu bài hát và phát nhạc hoàn toàn bình thường từ file cục bộ, không gặp bất kỳ độ trễ nào. Tính năng này giúp người dùng nghe nhạc thoải mái trên máy bay hoặc những khu vực không có sóng mạng."

#### 5. Module Trợ lý âm nhạc thông minh AI DJ (05:50 – 07:15)
* **Thao tác màn hình:** Chạm nút AI DJ phát sáng ở Home $\rightarrow$ Màn hình chat mở ra $\rightarrow$ Bấm chọn prompt gợi ý: *'Tạo playlist nhạc chill để tập trung học bài'* $\rightarrow$ AI phản hồi kèm danh sách bài hát $\rightarrow$ Bấm nút Play nghe thử ngay trong khung chat $\rightarrow$ Bấm nút 'Lưu thành Playlist'.
* **Lời thoại:**
> "Tiếp theo là điểm nhấn sáng tạo nhất của đồ án: **Trợ lý âm nhạc AI DJ**. Thay vì phải tự tìm kiếm bài hát theo cách thông thường, người dùng có thể trò chuyện tự nhiên với trợ lý ảo.  
> Ở đây, em gửi tin nhắn: *'Tạo playlist nhạc chill để tập trung học bài'*.  
> Yêu cầu lập tức được gửi tới Supabase Edge Function, nơi mô hình **Google Gemini AI** được tích hợp để phân tích ngữ cảnh, tâm trạng và sở thích nghe nhạc của người dùng. AI không chỉ phản hồi bằng ngôn ngữ tự nhiên mà còn đối chiếu trực tiếp với Catalog để trích xuất ra các bài hát phù hợp nhất.  
> Người dùng có thể bấm nghe thử ngay từng bài hát trong khung trò chuyện, và chỉ cần nhấn nút 'Lưu Playlist', AI DJ sẽ tự động khởi tạo danh sách phát mới vào Thư viện mà không cần thêm thủ công từng bài."

#### 6. Module Nâng cấp gói Premium VNPay & Tiện ích (07:15 – 08:15)
* **Thao tác màn hình:** Vào tab Cá nhân $\rightarrow$ Bấm Nâng cấp Premium $\rightarrow$ Chọn gói $\rightarrow$ Bấm thanh toán VNPay $\rightarrow$ Cửa sổ thanh toán VNPay Sandbox mở ra $\rightarrow$ Nhập thông tin thẻ test $\rightarrow$ Thanh toán thành công $\rightarrow$ Màn hình quay về app báo chúc mừng thành viên VIP $\rightarrow$ Mở menu Hẹn giờ ngủ (Sleep Timer) $\rightarrow$ Chuyển giao diện Dark/Light mode.
* **Lời thoại:**
> "Module cuối cùng là **Nâng cấp tài khoản Premium và Các tiện ích mở rộng**. Để mở khóa tính năng AI DJ không giới hạn và chuẩn âm thanh Lossless cao cấp, người dùng có thể nâng cấp gói dịch vụ. Nhóm đã tích hợp cổng thanh toán giả lập **VNPay Sandbox**.  
> Sau khi xác nhận giao dịch thành công tại cổng thanh toán, hệ thống tự động xử lý callback và kích hoạt ngay huy hiệu VIP trên hồ sơ cá nhân của người dùng.  
> Bên cạnh đó, ứng dụng còn cung cấp tiện ích 'Hẹn giờ tắt nhạc khi ngủ' (Sleep Timer) giúp tự động dừng phát nhạc sau thời gian định sẵn, cùng tính năng chuyển đổi giao diện linh hoạt giữa Dark OLED và Light Mode phù hợp với mọi điều kiện ánh sáng."

---

### PHẦN 4: TỔNG KẾT VÀ KẾT THÚC VIDEO (08:15 – 08:45)
* **Hình ảnh:** Chuyển màn hình chia sẻ sang trang GitHub của dự án (`https://github.com/Vinzxje016/MyTube`), camera hiển thị đầy đủ các thành viên chào giảng viên.
* **Lời thoại:**
> "Kính thưa Thầy/Cô, trên đây là toàn bộ phần demo các chức năng chính của đồ án ứng dụng nghe nhạc **MyTube Music**. Sản phẩm đã giải quyết trọn vẹn yêu cầu của học phần Lập trình di động, đảm bảo tính thẩm mỹ, hiệu năng mượt mà và khả năng ứng dụng thực tiễn cao.  
> Toàn bộ mã nguồn, tài liệu hướng dẫn và lịch sử commit của các thành viên đều được lưu trữ và cập nhật công khai tại địa chỉ GitHub: **github.com/Vinzxje016/MyTube**.  
>  
> Nhóm chúng em xin chân thành cảm ơn Thầy/Cô đã dành thời gian theo dõi video báo cáo của nhóm. Kính chúc Thầy/Cô dồi dào sức khỏe và công tác tốt!"

---

## IV. BẢNG CHECKLIST KIỂM TRA TRƯỚC KHI NỘP BÁO CÁO (7/7 ĐIỂM)

- [ ] **1. Thời lượng video:** Nằm trong khoảng 8 đến 9 phút (tuyệt đối không vượt quá 10 phút).
- [ ] **2. Xuất hiện camera:** Tất cả thành viên trong nhóm có mặt trên camera xuyên suốt video.
- [ ] **3. Tác phong & âm thanh:** Trang phục nghiêm túc, âm thanh thu âm rõ ràng, không bị rè hoặc mất tiếng.
- [ ] **4. Thao tác thực tế:** Toàn bộ chức năng phải được bấm và chạy trực tiếp, không dùng ảnh tĩnh.
- [ ] **5. Bảo mật dữ liệu:** Không hiển thị mật khẩu, Secret Key, Token, số thẻ ngân hàng thật trên màn hình.
- [ ] **6. Kho lưu trữ Git:** Link `https://github.com/Vinzxje016/MyTube` mở được bình thường (chế độ Public).
- [ ] **7. Lịch sử Git:** Có lịch sử làm việc trên 3 tuần và có commit đóng góp từ các thành viên.
- [ ] **8. File báo cáo:** Định dạng PDF/Word theo đúng mẫu của khoa, trong nội dung có ghi đầy đủ link Git.
- [ ] **9. Tên file rõ ràng:** Đặt tên file video và file báo cáo theo đúng cú pháp hướng dẫn của bộ môn.
- [ ] **10. Thư mục nộp:** Trong folder chung nộp bài có đủ đúng 01 file video demo và 01 file báo cáo.
