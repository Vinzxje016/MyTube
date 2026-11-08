import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';
import '../services/music_repository.dart';

class MusicPlayerController extends ChangeNotifier {
  static final MusicPlayerController _instance =
      MusicPlayerController._internal();
  factory MusicPlayerController() => _instance;

  MusicPlayerController._internal();

  AudioPlayer? _audioPlayer;
  Song? _currentSong;
  List<Song> _queue = [];
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _playbackRequested = false;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;
  bool _isShuffle = false;
  bool _isRepeat = false;
  final Set<String> _likedSongIds = {};
  int _likedStateRevision = 0;
  int _historyRevision = 0;
  int _playRequestRevision = 0;
  String? _playbackError;
  Duration _listeningTimeThisSession = Duration.zero;
  int _pendingListeningMilliseconds = 0;
  Duration? _lastListeningPosition;
  String? _lastListeningSongId;
  Timer? _sleepTimer;
  Timer? _sleepFadeTimer;
  bool _sleepUntilTrackEnds = false;
  bool _sleepFadeStarted = false;
  String? _sleepTimerLabel;

  static const _sleepFadeDuration = Duration(seconds: 8);

  AudioPlayer _ensureAudioPlayer() {
    final existing = _audioPlayer;
    if (existing != null) return existing;

    final player = AudioPlayer();
    _audioPlayer = player;
    unawaited(player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off));
    player.positionStream.listen((position) {
      final song = _currentSong;
      if (song != null &&
          (song.audioUrl != null || song.localAudioPath != null)) {
        _currentPosition = position;
        _recordAudibleProgress(song, position);
        if (_sleepUntilTrackEnds && !_sleepFadeStarted) {
          final remaining = (currentDuration ?? song.duration) - position;
          if (remaining <= _sleepFadeDuration) _beginSleepFade();
        }
        notifyListeners();
      }
    });
    player.durationStream.listen((duration) {
      if (duration != null &&
          (_currentSong?.audioUrl != null ||
              _currentSong?.localAudioPath != null)) {
        _currentDuration = duration;
        notifyListeners();
      }
    });
    player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        _flushListeningTime();
        if (_sleepUntilTrackEnds || _sleepFadeStarted) {
          _beginSleepFade();
          return;
        }
        nextSong();
      } else {
        if (wasPlaying && !state.playing) _flushListeningTime();
        notifyListeners();
      }
    });
    return player;
  }

  bool get _hasSignedInUser {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Song? get currentSong => _currentSong;
  List<Song> get queue => List.unmodifiable(_queue);
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get playbackError => _playbackError;
  Duration get currentPosition => _currentPosition;
  Duration? get currentDuration => _currentDuration ?? _currentSong?.duration;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  Set<String> get likedSongIds => Set.unmodifiable(_likedSongIds);
  int get likedStateRevision => _likedStateRevision;
  int get historyRevision => _historyRevision;
  Duration get listeningTimeThisSession => _listeningTimeThisSession;
  String? get sleepTimerLabel => _sleepTimerLabel;

  double get progressFraction {
    final duration = currentDuration;
    if (duration == null || duration.inSeconds == 0) return 0.0;
    return (_currentPosition.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  bool isLiked(String songId) => _likedSongIds.contains(songId);

  void restoreLikedSongIds(Set<String> songIds) {
    _likedStateRevision++;
    _likedSongIds
      ..clear()
      ..addAll(songIds);
    notifyListeners();
  }

  void clearUserState() {
    _likedStateRevision++;
    _likedSongIds.clear();
    notifyListeners();
  }

  void setQueue(List<Song> songs) {
    _queue = List.of(songs);
    if (_currentSong?.audioUrl == null &&
        _currentSong?.localAudioPath == null) {
      _currentSong = null;
      _currentPosition = Duration.zero;
      _currentDuration = null;
      _isPlaying = false;
      _playbackRequested = false;
    }
    notifyListeners();
  }

  void playSong(Song song, {List<Song>? newQueue}) {
    final requestRevision = ++_playRequestRevision;
    _currentSong = song;
    _playbackError = null;
    if (newQueue != null && newQueue.isNotEmpty) {
      _queue = List.of(newQueue);
    } else if (!_queue.any((item) => item.id == song.id)) {
      _queue = [song];
    }
    _currentPosition = Duration.zero;
    _currentDuration = song.duration;
    _isPlaying = false;
    _isLoading =
        song.localAudioPath == null &&
        song.audioUrl != null &&
        song.audioUrl!.isNotEmpty;
    _playbackRequested = true;
    _lastListeningPosition = null;
    _lastListeningSongId = song.id;
    if (_audioPlayer != null) unawaited(_audioPlayer!.pause());
    notifyListeners();

    if (song.localAudioPath == null &&
        (song.audioUrl == null || song.audioUrl!.isEmpty)) {
      _isPlaying = false;
      _isLoading = false;
      _playbackRequested = false;
      _playbackError = 'Bài hát này chưa có tệp âm thanh.';
      notifyListeners();
    } else {
      _ensureAudioPlayer();
      unawaited(_playSongSource(song, requestRevision));
    }
  }

  void _recordAudibleProgress(Song song, Duration position) {
    final previous = _lastListeningPosition;
    final sameSong = _lastListeningSongId == song.id;
    if (_isPlaying && sameSong && previous != null && position > previous) {
      final delta = position - previous;
      if (delta <= const Duration(seconds: 2)) {
        _pendingListeningMilliseconds += delta.inMilliseconds;
        _listeningTimeThisSession += delta;
        if (_pendingListeningMilliseconds >= 15000) _flushListeningTime();
      }
    }
    _lastListeningPosition = position;
    _lastListeningSongId = song.id;
  }

  void _flushListeningTime() {
    final milliseconds = _pendingListeningMilliseconds;
    if (milliseconds <= 0 || !_hasSignedInUser) return;
    final chunk = milliseconds.clamp(1, 30000);
    _pendingListeningMilliseconds -= chunk;
    unawaited(
      MusicRepository.instance
          .addListeningTime(Duration(milliseconds: chunk))
          .then((_) {
            _historyRevision++;
            notifyListeners();
          })
          .catchError((Object _) {
            _pendingListeningMilliseconds += chunk;
          }),
    );
  }

  void startSleepTimer(Duration duration) {
    cancelSleepTimer(notify: false);
    _sleepUntilTrackEnds = false;
    _sleepFadeStarted = false;
    _sleepTimerLabel = 'Còn ${duration.inMinutes} phút';
    _sleepTimer = Timer(duration, _beginSleepFade);
    notifyListeners();
  }

  void sleepAfterCurrentTrack() {
    cancelSleepTimer(notify: false);
    _sleepUntilTrackEnds = true;
    _sleepFadeStarted = false;
    _sleepTimerLabel = 'Sau bài hiện tại';
    final remaining = (currentDuration ?? Duration.zero) - _currentPosition;
    if (remaining <= _sleepFadeDuration) _beginSleepFade();
    notifyListeners();
  }

  void cancelSleepTimer({bool notify = true}) {
    final wasFading = _sleepFadeStarted;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepFadeTimer?.cancel();
    _sleepFadeTimer = null;
    _sleepUntilTrackEnds = false;
    _sleepFadeStarted = false;
    _sleepTimerLabel = null;
    if (wasFading && _audioPlayer != null) {
      unawaited(_audioPlayer!.setVolume(1));
    }
    if (notify) notifyListeners();
  }

  void _beginSleepFade() {
    if (_sleepFadeStarted) return;
    _sleepFadeStarted = true;
    _sleepTimer?.cancel();
    _sleepUntilTrackEnds = false;
    final player = _audioPlayer;
    if (player == null || !_isPlaying) {
      unawaited(_finishSleepTimer());
      return;
    }
    final startingVolume = player.volume;
    const steps = 40;
    var step = 0;
    _sleepTimerLabel = 'Đang giảm âm lượng';
    _sleepFadeTimer = Timer.periodic(
      Duration(milliseconds: _sleepFadeDuration.inMilliseconds ~/ steps),
      (timer) {
        step++;
        unawaited(player.setVolume(startingVolume * (1 - step / steps)));
        if (step >= steps) {
          timer.cancel();
          _sleepFadeTimer = null;
          unawaited(_finishSleepTimer());
        }
      },
    );
    notifyListeners();
  }

  Future<void> _finishSleepTimer() async {
    await _audioPlayer?.pause();
    await _audioPlayer?.setVolume(1);
    _isPlaying = false;
    _playbackRequested = false;
    _flushListeningTime();
    _sleepTimerLabel = null;
    _sleepFadeStarted = false;
    notifyListeners();
  }

  void _recordListeningStart(Song song) {
    if (!_hasSignedInUser) return;
    unawaited(
      MusicRepository.instance
          .recordPlay(song.id)
          .then((_) {
            _historyRevision++;
            notifyListeners();
          })
          .catchError((Object _) {}),
    );
  }

  Future<void> _playSongSource(Song song, int requestRevision) async {
    try {
      final refreshedSong =
          song.localAudioPath != null &&
              await File(song.localAudioPath!).exists()
          ? song
          : await MusicRepository.instance.refreshSong(song.id);
      if (requestRevision != _playRequestRevision ||
          _currentSong?.id != song.id) {
        return;
      }
      _currentSong = refreshedSong;
      final queueIndex = _queue.indexWhere((item) => item.id == song.id);
      if (queueIndex != -1) _queue[queueIndex] = refreshedSong;
      final coverUri = refreshedSong.coverUrl.startsWith('http')
          ? Uri.tryParse(refreshedSong.coverUrl)
          : null;
      final mediaItem = MediaItem(
        id: refreshedSong.id,
        title: refreshedSong.title,
        artist: refreshedSong.artist,
        album: refreshedSong.album,
        artUri: coverUri,
      );
      final audioSource = refreshedSong.localAudioPath != null
          ? AudioSource.file(refreshedSong.localAudioPath!, tag: mediaItem)
          : AudioSource.uri(Uri.parse(refreshedSong.audioUrl!), tag: mediaItem);
      await _ensureAudioPlayer().setAudioSource(audioSource);
      _isLoading = false;
      if (requestRevision == _playRequestRevision &&
          _currentSong?.id == song.id &&
          _playbackRequested) {
        await _ensureAudioPlayer().setVolume(1);
        final playback = _ensureAudioPlayer().play();
        _recordListeningStart(song);
        await playback;
      }
    } catch (error) {
      if (requestRevision == _playRequestRevision &&
          _currentSong?.id == song.id) {
        _isPlaying = false;
        _isLoading = false;
        _playbackRequested = false;
        _playbackError = error.toString();
        notifyListeners();
      }
    }
  }

  void togglePlayPause() {
    if (_currentSong == null) {
      if (_queue.isNotEmpty) {
        playSong(_queue.first);
      }
      return;
    }

    if (_currentSong!.localAudioPath == null &&
        (_currentSong!.audioUrl == null || _currentSong!.audioUrl!.isEmpty)) {
      _playbackError = 'Bài hát này chưa có tệp âm thanh.';
      notifyListeners();
      return;
    }

    final shouldPlay = !_playbackRequested;
    _playbackRequested = shouldPlay;
    _playbackError = null;
    if (_isLoading) {
      if (!shouldPlay) {
        _isPlaying = false;
        unawaited(_audioPlayer?.pause());
      }
      notifyListeners();
      return;
    }
    _isPlaying = shouldPlay;
    unawaited(_applyPlaybackState(shouldPlay));
    notifyListeners();
  }

  void retryPlayback() {
    final song = _currentSong;
    if (song == null) return;
    playSong(song, newQueue: _queue);
  }

  Future<void> _applyPlaybackState(bool shouldPlay) async {
    try {
      if (shouldPlay) {
        await _ensureAudioPlayer().play();
      } else {
        await _ensureAudioPlayer().pause();
      }
    } catch (error) {
      _isPlaying = false;
      _isLoading = false;
      _playbackRequested = false;
      _playbackError = error.toString();
      notifyListeners();
    }
  }

  void nextSong() {
    if (_queue.isEmpty || _currentSong == null) return;
    if (_isRepeat) {
      seekTo(Duration.zero);
      return;
    }

    final currentIndex = _queue.indexWhere(
      (song) => song.id == _currentSong!.id,
    );
    var nextIndex = currentIndex + 1;
    if (_isShuffle && _queue.length > 1) {
      do {
        nextIndex = math.Random().nextInt(_queue.length);
      } while (nextIndex == currentIndex);
    } else if (nextIndex >= _queue.length) {
      nextIndex = 0;
    }
    playSong(_queue[nextIndex], newQueue: _queue);
  }

  void previousSong() {
    if (_queue.isEmpty || _currentSong == null) return;
    if (_currentPosition.inSeconds > 3) {
      seekTo(Duration.zero);
      return;
    }

    final currentIndex = _queue.indexWhere(
      (song) => song.id == _currentSong!.id,
    );
    final previousIndex = currentIndex <= 0
        ? _queue.length - 1
        : currentIndex - 1;
    playSong(_queue[previousIndex], newQueue: _queue);
  }

  void seekTo(Duration position) {
    final maxDuration = _currentDuration ?? _currentSong?.duration;
    final clampedPosition = maxDuration == null
        ? position
        : Duration(
            milliseconds: position.inMilliseconds.clamp(
              0,
              maxDuration.inMilliseconds,
            ),
          );
    _currentPosition = clampedPosition;
    if (_currentSong?.audioUrl != null ||
        _currentSong?.localAudioPath != null) {
      unawaited(_ensureAudioPlayer().seek(clampedPosition));
    }
    notifyListeners();
  }

  void toggleLike(String songId) {
    _likedStateRevision++;
    final isNowLiked = !_likedSongIds.contains(songId);
    if (isNowLiked) {
      _likedSongIds.add(songId);
    } else {
      _likedSongIds.remove(songId);
    }
    notifyListeners();

    if (_hasSignedInUser) {
      unawaited(
        MusicRepository.instance
            .setSongLiked(songId, isNowLiked)
            .catchError((Object _) {}),
      );
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    if (_audioPlayer != null) {
      unawaited(
        _audioPlayer!.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _flushListeningTime();
    _sleepTimer?.cancel();
    _sleepFadeTimer?.cancel();
    _sleepTimer?.cancel();
    _sleepFadeTimer?.cancel();
    _flushListeningTime();
    if (_audioPlayer != null) unawaited(_audioPlayer!.dispose());
    super.dispose();
  }
}
