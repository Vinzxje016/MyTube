import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/main.dart';
import 'package:mytube/controllers/music_player_controller.dart';
import 'package:mytube/models/song_model.dart';
import 'package:mytube/services/ai_music_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1x1 transparent PNG bytes
final List<int> _kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

const _catalogTestSongs = [
  Song(
    id: 'test-1',
    title: 'Rainy Focus',
    artist: 'Test Artist',
    album: 'Test Album',
    duration: Duration(minutes: 3),
    coverUrl: '',
    tags: ['lofi', 'rain'],
  ),
  Song(
    id: 'test-2',
    title: 'Workout Energy',
    artist: 'Test Artist',
    album: 'Test Album',
    duration: Duration(minutes: 3),
    coverUrl: '',
    tags: ['gym', 'energy'],
  ),
];

void main() {
  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_test_key',
    );
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  test('MusicPlayerController logic test', () {
    final controller = MusicPlayerController();
    expect(controller.currentSong, isNull);
    expect(controller.isPlaying, isFalse);

    controller.togglePlayPause();
    expect(controller.isPlaying, isFalse);

    controller.nextSong();
    expect(controller.currentSong, isNull);
    expect(controller.queue, isEmpty);
  });

  test('queue navigation and seek stay in bounds without remote audio', () {
    final controller = MusicPlayerController();
    const first = Song(
      id: 'queue-first',
      title: 'First',
      artist: 'Artist',
      album: '',
      duration: Duration(seconds: 60),
      coverUrl: '',
    );
    const second = Song(
      id: 'queue-second',
      title: 'Second',
      artist: 'Artist',
      album: '',
      duration: Duration(seconds: 90),
      coverUrl: '',
    );

    controller.playSong(first, newQueue: const [first, second]);
    expect(controller.playbackError, isNotNull);
    controller.nextSong();
    expect(controller.currentSong?.id, second.id);
    controller.previousSong();
    expect(controller.currentSong?.id, first.id);
    controller.seekTo(const Duration(seconds: 90));
    expect(controller.currentPosition, const Duration(seconds: 60));
    controller.toggleShuffle();
    controller.nextSong();
    expect(controller.currentSong?.id, second.id);
    controller.toggleRepeat();
    controller.nextSong();
    expect(controller.currentSong?.id, second.id);
    expect(controller.currentPosition, Duration.zero);
    expect(() => controller.queue.add(second), throwsUnsupportedError);
  });

  test('liked state toggles and clears between user sessions', () {
    final controller = MusicPlayerController();
    controller.restoreLikedSongIds({'account-a-song'});
    expect(controller.isLiked('account-a-song'), isTrue);
    controller.clearUserState();
    expect(controller.isLiked('account-a-song'), isFalse);
    controller.toggleLike('account-b-song');
    expect(controller.isLiked('account-b-song'), isTrue);
  });

  test('Song model duration format test', () {
    const song = Song(
      id: 'test',
      title: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
      duration: Duration(minutes: 3, seconds: 25),
      coverUrl: '',
    );
    expect(song.durationString, '3:25');
  });

  test(
    'AiMusicService generates responses and habit recommendations',
    () async {
      final response = await AiMusicService.generateResponse(
        'tôi đang buồn',
        _catalogTestSongs,
      );
      expect(response.recommendedSongs.isNotEmpty, isTrue);
      expect(response.isUser, isFalse);

      final habit = AiMusicService.getHabitInsights(_catalogTestSongs);
      expect(habit['recommendedSongs'], isNotNull);
    },
  );

  testWidgets('App smoke test builds the sign-in screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyTubeMusicApp());
    await tester.pump();
    expect(find.text('Đăng nhập MyTube'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
  });

  testWidgets('sign-in form validates email and password before submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyTubeMusicApp());
    await tester.pump();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    expect(find.text('Nhập email hợp lệ'), findsOneWidget);
    expect(find.text('Mật khẩu cần ít nhất 6 ký tự'), findsOneWidget);
  });
}
