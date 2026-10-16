import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/main.dart';
import 'package:mytube/controllers/music_player_controller.dart';
import 'package:mytube/models/song_model.dart';
import 'package:mytube/services/ai_music_service.dart';

// 1x1 transparent PNG bytes
final List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
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

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  test('MusicPlayerController logic test', () {
    final controller = MusicPlayerController();
    expect(controller.currentSong, isNotNull);
    expect(controller.isPlaying, isFalse);

    controller.togglePlayPause();
    expect(controller.isPlaying, isTrue);

    controller.togglePlayPause();
    expect(controller.isPlaying, isFalse);

    final firstSongId = controller.currentSong!.id;
    controller.nextSong();
    expect(controller.currentSong!.id != firstSongId || controller.queue.length == 1, isTrue);
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

  test('AiMusicService generates responses and habit recommendations', () async {
    final response = await AiMusicService.generateResponse('tôi đang buồn');
    expect(response.recommendedSongs.isNotEmpty, isTrue);
    expect(response.isUser, isFalse);

    final habit = AiMusicService.getHabitInsights();
    expect(habit['recommendedSongs'], isNotNull);
  });

  testWidgets('App smoke test builds main navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyTubeMusicApp());
    await tester.pump();
    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);
    expect(find.text('Thư viện'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);
  });
}
