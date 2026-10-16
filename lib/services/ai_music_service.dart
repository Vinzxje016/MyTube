import '../models/chat_message_model.dart';
import '../models/song_model.dart';

class AiMusicService {
  static final List<Song> _allSongs = MusicData.sampleSongs;

  static ChatMessage getInitialMessage() {
    return ChatMessage(
      id: 'msg_welcome',
      text:
          'Xin chào Alex! 🎧 Mình là **AI DJ** của MyTube. Hôm nay tâm trạng của bạn thế nào, hay bạn đang làm việc gì? Hãy nói cho mình biết để mình gợi ý những giai điệu phù hợp nhất cho bạn nhé!',
      isUser: false,
      timestamp: DateTime.now(),
      quickReplies: const [
        '🌧️ Nhạc buồn ngắm mưa',
        '⚡ Nhạc sung tập Gym',
        '☕ Lo-Fi tập trung làm việc',
        '🌙 Nhạc êm dịu dễ ngủ',
      ],
    );
  }

  static Future<ChatMessage> generateResponse(String userPrompt) async {
    // Simulate natural thinking delay
    await Future.delayed(const Duration(milliseconds: 700));

    final prompt = userPrompt.toLowerCase().trim();
    List<Song> matchedSongs = [];
    String replyText = '';
    List<String> quickReplies = [];

    if (prompt.contains('gym') ||
        prompt.contains('tap luyen') ||
        prompt.contains('tập') ||
        prompt.contains('chay bo') ||
        prompt.contains('chạy') ||
        prompt.contains('sung') ||
        prompt.contains('nang luong') ||
        prompt.contains('năng lượng') ||
        prompt.contains('soi dong') ||
        prompt.contains('sôi động')) {
      matchedSongs = _allSongs
          .where((s) => s.tags.any((t) => ['workout', 'gym', 'energy', 'soi dong'].contains(t)))
          .toList();
      replyText =
          'Bật tối đa năng lượng nào! ⚡ Dưới đây là những giai điệu có nhịp điệu dồn dập, bùng nổ giúp bạn bứt phá mọi giới hạn tập luyện hôm nay:';
      quickReplies = ['🔥 Thêm bài khác', '🎧 Bật playlist tập luyện', '🌙 Chuyển sang thả lỏng'];
    } else if (prompt.contains('buon') ||
        prompt.contains('buồn') ||
        prompt.contains('tam trang') ||
        prompt.contains('tâm trạng') ||
        prompt.contains('that tinh') ||
        prompt.contains('thất tình') ||
        prompt.contains('co don') ||
        prompt.contains('cô đơn') ||
        prompt.contains('nỗi sầu')) {
      matchedSongs = _allSongs
          .where((s) => s.tags.any((t) => ['buon', 'sad', 'tam trang', 'that tinh'].contains(t)))
          .toList();
      replyText =
          'Mình hiểu cảm giác này... 🌧️ Đôi khi âm nhạc chính là liều thuốc xoa dịu tâm hồn tốt nhất. Hãy để những giai điệu này đồng cảm cùng bạn nhé:';
      quickReplies = ['🌧️ Nghe tiếng mưa rơi', '☕ Đổi sang nhạc tích cực', '❤️ Lưu vào yêu thích'];
    } else if (prompt.contains('mua') ||
        prompt.contains('mưa') ||
        prompt.contains('rain')) {
      matchedSongs = _allSongs
          .where((s) => s.tags.any((t) => ['mua', 'rain', 'lofi', 'acoustic'].contains(t)))
          .toList();
      replyText =
          'Tiếng mưa rơi tí tách ngoài hiên kết hợp cùng những nốt nhạc nhẹ nhàng là combo hoàn hảo. Thư giãn cùng những bài hát này nhé:';
      quickReplies = ['☕ Lo-Fi chill', '🎧 Nhạc Acoustic Đen Vâu', '🌙 Nhạc đêm'];
    } else if (prompt.contains('tap trung') ||
        prompt.contains('tập trung') ||
        prompt.contains('hoc') ||
        prompt.contains('học') ||
        prompt.contains('lam viec') ||
        prompt.contains('làm việc') ||
        prompt.contains('doc sach') ||
        prompt.contains('đọc sách') ||
        prompt.contains('lofi') ||
        prompt.contains('lo-fi')) {
      matchedSongs = _allSongs
          .where((s) => s.tags.any((t) => ['focus', 'tap trung', 'hoc tap', 'lam viec', 'lofi'].contains(t)))
          .toList();
      replyText =
          'Để tập trung cao độ và nâng cao hiệu suất làm việc/học tập, những giai điệu Lo-Fi và Acoustic mộc mạc này sẽ giúp bạn loại bỏ mọi phiền nhiễu:';
      quickReplies = ['☕ Nhạc cà phê sáng', '🌙 Chuyển sang nhạc ngủ', '⚡ Cần tỉnh ngủ'];
    } else if (prompt.contains('ngu') ||
        prompt.contains('ngủ') ||
        prompt.contains('dem') ||
        prompt.contains('đêm') ||
        prompt.contains('khuya') ||
        prompt.contains('thu gian') ||
        prompt.contains('thư giãn')) {
      matchedSongs = _allSongs
          .where((s) => s.tags.any((t) => ['night', 'dem', 'chill', 'ngu', 'lofi'].contains(t)))
          .toList();
      replyText =
          'Chúc Alex có những phút giây thư giãn thật êm đềm và một giấc ngủ ngon lành. Đây là danh sách bài hát nhẹ dịu ru êm tâm trí bạn:';
      quickReplies = ['⏰ Hẹn giờ tắt sau 30 phút', '🌧️ Thêm tiếng mưa', '☕ Nhạc sáng mai'];
    } else if (prompt.contains('vui') ||
        prompt.contains('yeu') ||
        prompt.contains('yêu') ||
        prompt.contains('lang man') ||
        prompt.contains('lãng mạn') ||
        prompt.contains('happy')) {
      matchedSongs = _allSongs
          .where((s) => s.tags.any((t) => ['love', 'lang man', 'happy', 'vui ve'].contains(t)))
          .toList();
      replyText =
          'Năng lượng tình yêu và niềm vui ngập tràn! ❤️ Cùng hòa mình vào những giai điệu ngọt ngào, tươi vui này nhé:';
      quickReplies = ['💖 Nhạc tình yêu V-Pop', '⚡ Nhạc tiệc tùng', '☕ Acoustic chiều'];
    } else if (prompt.contains('đen') ||
        prompt.contains('den vau') ||
        prompt.contains('đen vâu')) {
      matchedSongs = _allSongs.where((s) => s.artist.toLowerCase().contains('đen')).toList();
      replyText =
          'Fan của chú Đen đây rồi! 🌲 Những ca từ mộc mạc, triết lý và gần gũi của Đen Vâu sẵn sàng phục vụ bạn:';
      quickReplies = ['☕ Thêm nhạc Acoustic', '⚡ Đổi sang The Weeknd', '🌧️ Lo-Fi Chill'];
    } else if (prompt.contains('weeknd') || prompt.contains('starboy')) {
      matchedSongs = _allSongs.where((s) => s.artist.toLowerCase().contains('weeknd')).toList();
      replyText =
          'Chất giọng mê hoặc đặc trưng của The Weeknd! Cùng đắm chìm trong giai điệu synthwave cuốn hút:';
      quickReplies = ['⚡ Nhạc năng lượng cao', '🌙 Nhạc đêm khuya', '🎶 Top Hits Quốc tế'];
    } else {
      // General match or fallback based on title/artist
      matchedSongs = _allSongs.where((s) {
        return s.title.toLowerCase().contains(prompt) ||
            s.artist.toLowerCase().contains(prompt) ||
            s.tags.any((t) => prompt.contains(t));
      }).toList();

      if (matchedSongs.isEmpty) {
        matchedSongs = [_allSongs[0], _allSongs[2], _allSongs[6]];
        replyText =
            'Mình đã lắng nghe bạn! Dựa trên gu nghe nhạc thường ngày của bạn, đây là 3 ca khúc được chọn lọc kỹ lưỡng dành riêng cho bạn lúc này:';
      } else {
        replyText = 'Dưới đây là các ca khúc rất phù hợp với yêu cầu "$userPrompt" của bạn:';
      }
      quickReplies = ['🔥 Đổi vibe khác', '🌧️ Nhạc buồn sâu lắng', '⚡ Nhạc sung tập gym'];
    }

    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      recommendedSongs: matchedSongs,
      quickReplies: quickReplies,
    );
  }

  // Habit-based recommendations
  static Map<String, dynamic> getHabitInsights() {
    final now = DateTime.now();
    final hour = now.hour;

    String timeContext;
    String insightText;
    List<Song> recommended;

    if (hour >= 5 && hour < 12) {
      timeContext = 'Buổi sáng tỉnh táo';
      insightText = 'Bạn thường nghe nhạc Acoustic & V-Pop tươi vui vào khung giờ 07:00 - 09:00';
      recommended = [_allSongs[2], _allSongs[4], _allSongs[0]];
    } else if (hour >= 12 && hour < 18) {
      timeContext = 'Buổi chiều tập trung';
      insightText = 'Bạn thường nghe Lo-Fi & Instrumental để làm việc hiệu quả vào buổi chiều';
      recommended = [_allSongs[6], _allSongs[2], _allSongs[3]];
    } else {
      timeContext = 'Đêm muộn thư giãn';
      insightText = 'Thói quen nghe nhạc: 70% Lo-Fi, R&B & Chill vào khoảng 21:00 - 23:30';
      recommended = [_allSongs[6], _allSongs[0], _allSongs[3], _allSongs[7]];
    }

    return {
      'timeContext': timeContext,
      'insightText': insightText,
      'recommendedSongs': recommended,
    };
  }

  static List<Song> getSongsByMood(String moodKey) {
    switch (moodKey) {
      case 'chill_night':
        return _allSongs
            .where((s) => s.tags.any((t) => ['night', 'lofi', 'chill'].contains(t)))
            .toList();
      case 'workout':
        return _allSongs
            .where((s) => s.tags.any((t) => ['workout', 'gym', 'energy'].contains(t)))
            .toList();
      case 'focus':
        return _allSongs
            .where((s) => s.tags.any((t) => ['focus', 'tap trung', 'lofi', 'acoustic'].contains(t)))
            .toList();
      case 'rainy_mood':
        return _allSongs
            .where((s) => s.tags.any((t) => ['mua', 'rain', 'buon', 'sad'].contains(t)))
            .toList();
      case 'love':
        return _allSongs
            .where((s) => s.tags.any((t) => ['love', 'lang man', 'happy'].contains(t)))
            .toList();
      default:
        return _allSongs;
    }
  }
}
