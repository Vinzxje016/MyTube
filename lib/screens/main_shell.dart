import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../controllers/music_player_controller.dart';
import '../services/music_repository.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _restoreLikesForCurrentUser();
  }

  void _restoreLikesForCurrentUser() {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    final player = MusicPlayerController();
    final revision = player.likedStateRevision;
    unawaited(
      MusicRepository.instance.getLikedSongIds().then((songIds) {
        if (client.auth.currentUser?.id == userId &&
            player.likedStateRevision == revision) {
          player.restoreLikedSongIds(songIds);
        }
      }, onError: (Object _) {}),
    );
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Screens Stack
          IndexedStack(index: _currentIndex, children: _screens),

          // Pinned Floating Mini Player and Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Mini Player
                const MiniPlayer(),

                // Frosted Glass Bottom Navigation Bar
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor.withAlpha(245),
                        border: Border(
                          top: BorderSide(
                            color: context.borderColor,
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: BottomNavigationBar(
                          currentIndex: _currentIndex,
                          onTap: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          items: const [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home_filled),
                              activeIcon: Icon(
                                Icons.home_filled,
                                color: AppTheme.primaryLight,
                              ),
                              label: 'Khám phá',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.search_rounded),
                              activeIcon: Icon(
                                Icons.search_rounded,
                                color: AppTheme.primaryLight,
                              ),
                              label: 'Tìm kiếm',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.library_music_rounded),
                              activeIcon: Icon(
                                Icons.library_music_rounded,
                                color: AppTheme.primaryLight,
                              ),
                              label: 'Thư viện',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.person_rounded),
                              activeIcon: Icon(
                                Icons.person_rounded,
                                color: AppTheme.primaryLight,
                              ),
                              label: 'Cá nhân',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
