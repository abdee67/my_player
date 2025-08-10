import 'dart:typed_data';
import 'package:flutter/material.dart';

class AlbumArt extends StatelessWidget {
  final Uint8List? albumArt;
  final double size;
  final Animation<double>? animation;
  final String fallbackAsset;

  const AlbumArt({
    super.key,
    required this.albumArt,
    this.size = 220,
    this.animation,
    this.fallbackAsset = 'assets/default_album_art.png',
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation ?? const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: albumArt != null && albumArt!.isNotEmpty
              ? Image.memory(albumArt!, fit: BoxFit.cover)
              : Image.asset(fallbackAsset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
