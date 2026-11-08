import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import '../models/song_model.dart';

class AiMusicService {
  static ChatMessage getInitialMessage() => ChatMessage(
    id: 'msg_welcome',
    text:
        'Chào bạn! Mình có thể trò chuyện về âm nhạc và chọn bài trong catalog để tạo playlist. Bạn đang muốn nghe gì?',
    isUser: false,
    timestamp: DateTime.now(),
    quickReplies: const [
      'Tạo playlist nhạc chill',
      'Nhạc tập trung',
      'Nhạc tập gym',
      'Nhạc buồn',
    ],
  );

  static Future<ChatMessage> generateResponse(
    String userPrompt,
    List<Song> catalog, {
    List<ChatMessage>? conversation,
  }) async {
    final messages = conversation ?? [
      ChatMessage(
        id: 'msg_request',
        text: userPrompt,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];
    final requestMessages = messages
        .where((message) => message.id != 'msg_welcome')
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList();
    final boundedMessages = requestMessages.length > 30
        ? requestMessages.sublist(requestMessages.length - 30)
        : requestMessages;
    late final dynamic response;
    try {
      response = await Supabase.instance.client.functions.invoke(
        'ai-dj',
        body: {'messages': boundedMessages},
      );
    } on FunctionException catch (error) {
      final details = error.details;
      Map? payload = details is Map ? details : null;
      if (payload == null && details is String) {
        try {
          final decoded = jsonDecode(details);
          if (decoded is Map) payload = decoded;
        } catch (_) {}
      }
      final code = payload?['code'];
      final providerDetails = payload?['details'];
      throw AiMusicException(switch (code) {
        'PREMIUM_REQUIRED' =>
          'AI DJ chỉ dành cho người dùng Premium. Hãy đăng ký để tiếp tục.',
        'SUBSCRIPTION_UNAVAILABLE' =>
          'Chưa kiểm tra được trạng thái Premium. Hãy thử lại sau.',
        'GEMINI_NOT_CONFIGURED' =>
          'Chưa cấu hình GEMINI_API_KEY trong Supabase secrets.',
        'GEMINI_QUOTA' =>
          'Gemini đã hết hạn mức hiện tại. Kiểm tra quota hoặc billing của API key.',
        'GEMINI_TIMEOUT' =>
          'Gemini phản hồi quá chậm. Hãy thử lại sau ít phút.',
        'GEMINI_API_ERROR' =>
          'Gemini từ chối yêu cầu: ${providerDetails ?? 'kiểm tra model và API key.'}',
        'CATALOG_UNAVAILABLE' =>
          'Supabase chưa đọc được catalog bài hát. Kiểm tra quyền truy cập và migrations.',
        'INVALID_SESSION' || 'AUTH_REQUIRED' =>
          'Phiên đăng nhập đã hết hạn. Hãy đăng xuất rồi đăng nhập lại.',
        _ => 'Edge Function ai-dj trả lỗi HTTP ${error.status}. Kiểm tra log function trên Supabase.',
      });
    }
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid AI response.');
    }

    final songById = {for (final song in catalog) song.id: song};
    final songs = (data['songIds'] as List? ?? const [])
        .whereType<String>()
        .toSet()
        .map((id) => songById[id])
        .whereType<Song>()
        .toList();
    final playlistDraft = data['playlistDraft'] == true && songs.isNotEmpty;
    final title = data['playlistName'] is String
        ? (data['playlistName'] as String).trim()
        : '';

    return ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      text: data['reply'] is String
          ? data['reply'] as String
          : 'Mình chưa tạo được gợi ý lần này. Bạn thử mô tả tâm trạng hoặc thể loại nhé.',
      isUser: false,
      timestamp: DateTime.now(),
      recommendedSongs: songs,
      quickReplies: const [
        'Tạo playlist khác',
        'Bài khác cùng tâm trạng',
        'Đổi sang nhạc tập trung',
      ],
      playlistTitle: playlistDraft && title.isNotEmpty ? title : null,
      isPlaylistDraft: playlistDraft && title.isNotEmpty,
    );
  }

  static Map<String, dynamic> getHabitInsights(List<Song> songs) {
    final hour = DateTime.now().hour;
    final terms = hour >= 5 && hour < 12
        ? const ['acoustic', 'pop', 'vui', 'morning']
        : hour < 18
        ? const ['lofi', 'focus', 'acoustic', 'chill']
        : const ['night', 'chill', 'lofi', 'relax'];
    final recommendations = _filterSongs(songs, terms);
    return {
      'insightText': songs.isEmpty
          ? 'Bài hát trong catalog sẽ xuất hiện ở đây.'
          : 'Gợi ý được chọn từ ${songs.length} bài hát trong thư viện của bạn.',
      'recommendedSongs': recommendations.isEmpty
          ? songs.take(3).toList()
          : recommendations.take(3).toList(),
    };
  }

  static List<Song> getSongsByMood(String moodKey, List<Song> songs) {
    final terms = switch (moodKey) {
      'workout' => const ['workout', 'gym', 'energy', 'tập luyện'],
      'focus' => const ['focus', 'tập trung', 'học tập', 'lofi', 'acoustic'],
      'rainy_mood' => const ['mưa', 'rain', 'buồn', 'sad', 'acoustic'],
      'love' => const ['love', 'tình yêu', 'romantic', 'lãng mạn'],
      _ => const ['night', 'lofi', 'chill', 'thư giãn'],
    };
    final matches = _filterSongs(songs, terms);
    return matches.isEmpty ? songs : matches;
  }

  static List<Song> _filterSongs(List<Song> songs, List<String> terms) {
    return songs.where((song) {
      final searchable =
          '${song.title} ${song.artist} ${song.album} ${song.tags.join(' ')}'
              .toLowerCase();
      return terms.any((term) => searchable.contains(term.toLowerCase()));
    }).toList();
  }
}

class AiMusicException implements Exception {
  final String message;

  const AiMusicException(this.message);

  @override
  String toString() => message;
}
