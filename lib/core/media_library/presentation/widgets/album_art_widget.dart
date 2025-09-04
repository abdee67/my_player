import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlbumArtWidget extends StatefulWidget {
  final int songId;
  final Uint8List? albumArt;
  final double radius;
  final String? fallbackAsset;

  const AlbumArtWidget({
    super.key,
    required this.songId,
    this.albumArt,
    this.radius = 28,
    this.fallbackAsset = 'assets/default_album_art.png',
  });

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  Uint8List? _artwork;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.albumArt == null) {
      _fetchArtwork();
    }
  }

  Future<void> _fetchArtwork() async {
    setState(() => _loading = true);
    try {
      if (widget.songId == 0) {
        // Invalid ID, skip fetch
        if (mounted) setState(() => _artwork = null);
        return;
      }
      final art = await OnAudioQuery().queryArtwork(
        widget.songId,
        ArtworkType.AUDIO,
        size: 200,
        quality: 50,
      );
      if (mounted) setState(() => _artwork = art);
    } catch (e) {
      debugPrint('AlbumArtWidget: Failed to fetch artwork for songId ${widget.songId}: $e');
      if (mounted) setState(() => _artwork = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.albumArt ?? _artwork;
    if (_loading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey.shade800,
        child: SizedBox(
          width: 18,
          height: 18,
          child: SpinKitSpinningLines(
            color: Colors.blue,
            size: 30,
          ),
        ),
      );
    }
    if (art != null && art.isNotEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: MemoryImage(art),
      );
    }
    // Always show fallback if artwork is missing or failed
    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: AssetImage(widget.fallbackAsset ?? 'assets/default_album_art.png'),
      child: Icon(Icons.music_note, color: Colors.white24, size: widget.radius),
    );
  }
}
