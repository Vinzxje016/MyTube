import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CoverArtwork extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final IconData fallbackIcon;

  const CoverArtwork({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fallbackIcon = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Builder(
    builder: (context) => Container(
      width: width,
      height: height,
      color: context.raisedSurfaceColor,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: context.mutedTextColor),
    ),
  );
}
