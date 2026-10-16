import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song_model.dart';

class MusicPlayerController extends ChangeNotifier {
  static final MusicPlayerController _instance = MusicPlayerController._internal();
  factory MusicPlayerController() => _instance;

  MusicPlayerController._internal() {
    _currentSong = MusicData.sampleSongs.first;
    _queue = List.from(MusicData.sampleSongs);
    _likedSongIds.add('1');
    _likedSongIds.add('3');
  }

  Song? _currentSong;
  List<Song> _queue = [];
  bool _isPlaying = false;
  Duration _currentPosition = const Duration(seconds: 42);
  bool _isShuffle = false;
  bool _isRepeat = false;
  final Set<String> _likedSongIds = {};
  Timer? _progressTimer;

  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  Set<String> get likedSongIds => _likedSongIds;

  double get progressFraction {
    if (_currentSong == null || _currentSong!.duration.inSeconds == 0) return 0.0;
    return (_currentPosition.inSeconds / _currentSong!.duration.inSeconds).clamp(0.0, 1.0);
  }

  bool isLiked(String songId) => _likedSongIds.contains(songId);

  void playSong(Song song, {List<Song>? newQueue}) {
    _currentSong = song;
    if (newQueue != null && newQueue.isNotEmpty) {
      _queue = List.from(newQueue);
    }
    _currentPosition = Duration.zero;
    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_currentSong == null && _queue.isNotEmpty) {
      _currentSong = _queue.first;
    }
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _startTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  void nextSong() {
    if (_queue.isEmpty || _currentSong == null) return;

    if (_isRepeat) {
      _currentPosition = Duration.zero;
      notifyListeners();
      return;
    }

    final currentIndex = _queue.indexWhere((s) => s.id == _currentSong!.id);
    if (currentIndex != -1 && currentIndex < _queue.length - 1) {
      _currentSong = _queue[currentIndex + 1];
    } else {
      // Loop back to start
      _currentSong = _queue.first;
    }
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void previousSong() {
    if (_queue.isEmpty || _currentSong == null) return;

    // If more than 3 seconds in, restart current song
    if (_currentPosition.inSeconds > 3) {
      _currentPosition = Duration.zero;
      notifyListeners();
      return;
    }

    final currentIndex = _queue.indexWhere((s) => s.id == _currentSong!.id);
    if (currentIndex > 0) {
      _currentSong = _queue[currentIndex - 1];
    } else {
      _currentSong = _queue.last;
    }
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void seekTo(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  void toggleLike(String songId) {
    if (_likedSongIds.contains(songId)) {
      _likedSongIds.remove(songId);
    } else {
      _likedSongIds.add(songId);
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  void _startTimer() {
    _stopTimer();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying || _currentSong == null) {
        timer.cancel();
        return;
      }

      if (_currentPosition < _currentSong!.duration) {
        _currentPosition += const Duration(seconds: 1);
        notifyListeners();
      } else {
        nextSong();
      }
    });
  }

  void _stopTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
