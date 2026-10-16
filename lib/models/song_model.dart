import 'package:flutter/material.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String coverUrl;
  final Color accentColor;
  final List<String> lyrics;
  final bool isExplicit;
  final List<String> tags;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.coverUrl,
    this.accentColor = const Color(0xFF7C3AED),
    this.lyrics = const [],
    this.isExplicit = false,
    this.tags = const [],
  });

  String get durationString {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<Song> songs;
  final List<Color> gradientColors;

  const Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.songs,
    this.gradientColors = const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  });

  int get trackCount => songs.length;
}

class Artist {
  final String id;
  final String name;
  final String avatarUrl;
  final String monthlyListeners;
  final bool isVerified;

  const Artist({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.monthlyListeners,
    this.isVerified = true,
  });
}

class MusicData {
  static const List<Song> sampleSongs = [
    Song(
      id: '1',
      title: 'Cắt Đôi Nỗi Sầu',
      artist: 'Tăng Duy Tân, Drum7',
      album: 'Single Hit 2024',
      duration: Duration(minutes: 3, seconds: 12),
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&auto=format&fit=crop&q=80',
      accentColor: Color(0xFF8B5CF6),
      tags: ['buon', 'sad', 'tam trang', 'that tinh', 'vpop', 'night', 'chill'],
      lyrics: [
        'Cắt đôi nỗi sầu anh buông tay',
        'Cắt đi nỗi buồn sâu thẳm này',
        'Để cho cơn gió đưa tình bay',
        'Về nơi phương trời xa ngút ngàn...',
        'Từng dòng ký ức như vết thương',
        'Gieo bao vấn vương qua tháng năm dài',
        'Còn lại gì sau những đắm say...',
      ],
    ),
    Song(
      id: '2',
      title: 'Starboy',
      artist: 'The Weeknd, Daft Punk',
      album: 'Starboy',
      duration: Duration(minutes: 3, seconds: 50),
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      accentColor: Color(0xFFE11D48),
      tags: ['workout', 'gym', 'energy', 'soi dong', 'chay bo', 'party', 'pop'],
      lyrics: [
        "I'm tryna put you in the worst mood, ah",
        'P1 cleaner than your church shoes, ah',
        'Milli point two just to hurt you, ah',
        'All red Lamb\' just to tease you, ah',
        'Look what you\'ve done',
        'I\'m a motherfuckin\' starboy',
      ],
      isExplicit: true,
    ),
    Song(
      id: '3',
      title: 'Nấu Ăn Cho Em',
      artist: 'Đen Vâu, PiaLinh',
      album: 'Đen Vâu Acoustic Collection',
      duration: Duration(minutes: 4, seconds: 15),
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
      accentColor: Color(0xFF10B981),
      tags: ['chill', 'acoustic', 'tap trung', 'hoc tap', 'lam viec', 'thu gian', 'binh yen', 'den vau'],
      lyrics: [
        'Mặt trời vàng như lòng đỏ trứng gà',
        'Đổ xuống trên triền dốc cao ngút ngàn',
        'Nấu cho các em bữa cơm ấm nồng',
        'Để nụ cười rạng rỡ giữa mùa đông',
      ],
    ),
    Song(
      id: '4',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: Duration(minutes: 4, seconds: 3),
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&auto=format&fit=crop&q=80',
      accentColor: Color(0xFF06B6D4),
      tags: ['night', 'chill', 'dem', 'lai xe', 'electronic', 'tap trung', 'lofi'],
      lyrics: [
        'Waiting in a car',
        'Waiting for a ride in the dark',
        'The night city grows',
        'Look and see her eyes, they glow',
      ],
    ),
    Song(
      id: '5',
      title: 'Ngày Đầu Tiên',
      artist: 'Đức Phúc',
      album: 'Valentine Special',
      duration: Duration(minutes: 3, seconds: 28),
      coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&auto=format&fit=crop&q=80',
      accentColor: Color(0xFFEC4899),
      tags: ['love', 'lang man', 'tinh yeu', 'happy', 'vui ve', 'vpop', 'dam cuoi'],
      lyrics: [
        'Nhiều khi anh tự hỏi chính mình',
        'Sau bao thăng trầm và đổi thay',
        'Điều tuyệt vời nhất anh có được',
        'Chính là ngày đầu tiên gặp em...',
      ],
    ),
    Song(
      id: '6',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      duration: Duration(minutes: 3, seconds: 20),
      coverUrl: 'https://images.unsplash.com/photo-1487180144351-b8472da7d491?w=600&auto=format&fit=crop&q=80',
      accentColor: Color(0xFFF59E0B),
      tags: ['workout', 'energy', 'gym', 'chay bo', '80s', 'synthwave', 'the weeknd', 'soi dong'],
      lyrics: [
        'I\'ve been tryna call',
        'I\'ve been on my own for long enough',
        'Maybe you can show me how to love, maybe',
        'I\'m blinded by the lights...',
      ],
    ),
    Song(
      id: '7',
      title: 'Mưa Rơi Bên Cửa Sổ (Lo-Fi Beats)',
      artist: 'Lofi Coffee Club',
      album: 'Rainy Day Cafe',
      duration: Duration(minutes: 2, seconds: 45),
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80',
      accentColor: Color(0xFF6366F1),
      tags: ['lofi', 'mua', 'rain', 'hoc tap', 'tap trung', 'ngu', 'dem', 'chill', 'khong loi'],
      lyrics: [
        '[Nhạc không lời - Tiếng mưa rơi êm dịu kết hợp piano thư giãn]',
      ],
    ),
    Song(
      id: '8',
      title: 'Từng Quen',
      artist: 'Wren Evans, itsnk',
      album: 'Loi Choi',
      duration: Duration(minutes: 3, seconds: 5),
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&auto=format&fit=crop&q=80',
      accentColor: Color(0xFFA855F7),
      tags: ['vpop', 'rnb', 'chill', 'tam trang', 'tinh yeu', 'gen z'],
      lyrics: [
        'Ta từng quen nhau chưa nhỉ?',
        'Hình như anh đã thấy em ở đâu',
        'Trong một giấc mơ êm đềm...',
      ],
    ),
  ];

  static const List<Artist> topArtists = [
    Artist(
      id: 'a1',
      name: 'Đen Vâu',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
      monthlyListeners: '2.8M người nghe hàng tháng',
    ),
    Artist(
      id: 'a2',
      name: 'The Weeknd',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
      monthlyListeners: '105M người nghe hàng tháng',
    ),
    Artist(
      id: 'a3',
      name: 'Sơn Tùng M-TP',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
      monthlyListeners: '4.1M người nghe hàng tháng',
    ),
    Artist(
      id: 'a4',
      name: 'Taylor Swift',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
      monthlyListeners: '98M người nghe hàng tháng',
    ),
    Artist(
      id: 'a5',
      name: 'Vũ.',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&auto=format&fit=crop&q=80',
      monthlyListeners: '1.9M người nghe hàng tháng',
    ),
  ];

  static List<Playlist> get samplePlaylists => [
    Playlist(
      id: 'p1',
      title: 'Top Hits Việt Nam',
      description: 'Những ca khúc V-Pop đang làm mưa làm gió hiện nay.',
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&auto=format&fit=crop&q=80',
      songs: sampleSongs,
      gradientColors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    Playlist(
      id: 'p2',
      title: 'Lo-Fi Chill & Học Tập',
      description: 'Giai điệu thư giãn nhẹ nhàng giúp bạn tập trung làm việc.',
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=600&auto=format&fit=crop&q=80',
      songs: [sampleSongs[6], sampleSongs[2], sampleSongs[3]],
      gradientColors: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    ),
    Playlist(
      id: 'p3',
      title: 'Workout Energy Boost',
      description: 'Bùng nổ năng lượng cho buổi tập luyện tràn đầy hứng khởi.',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      songs: [sampleSongs[1], sampleSongs[5], sampleSongs[3]],
      gradientColors: const [Color(0xFFF97316), Color(0xFFEF4444)],
    ),
    Playlist(
      id: 'p4',
      title: 'Acoustic Buổi Chiều',
      description: 'Mộc mạc tiếng guitar cùng những câu chuyện chiều mưa.',
      coverUrl: 'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=600&auto=format&fit=crop&q=80',
      songs: [sampleSongs[2], sampleSongs[4], sampleSongs[0]],
      gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
    ),
  ];

  static const List<Map<String, dynamic>> musicGenres = [
    {
      'title': 'V-Pop',
      'colors': [Color(0xFFEC4899), Color(0xFFBE185D)],
      'icon': Icons.music_note_rounded,
    },
    {
      'title': 'Lo-Fi & Chill',
      'colors': [Color(0xFF6366F1), Color(0xFF4338CA)],
      'icon': Icons.nightlight_round,
    },
    {
      'title': 'Hip-Hop & Rap',
      'colors': [Color(0xFFF59E0B), Color(0xFFD97706)],
      'icon': Icons.mic_external_on_rounded,
    },
    {
      'title': 'EDM & Dance',
      'colors': [Color(0xFF06B6D4), Color(0xFF0284C7)],
      'icon': Icons.graphic_eq_rounded,
    },
    {
      'title': 'Indie & Acoustic',
      'colors': [Color(0xFF10B981), Color(0xFF047857)],
      'icon': Icons.radio_rounded,
    },
    {
      'title': 'K-Pop',
      'colors': [Color(0xFFA855F7), Color(0xFF7E22CE)],
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Rock & Metal',
      'colors': [Color(0xFFEF4444), Color(0xFFB91C1C)],
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'title': 'Podcast & Radio',
      'colors': [Color(0xFF64748B), Color(0xFF334155)],
      'icon': Icons.podcasts_rounded,
    },
  ];
}
