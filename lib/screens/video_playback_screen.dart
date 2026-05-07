import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/video_model.dart';

/// Full-screen playback for a saved VideoModel (YouTube or local).
class VideoPlaybackScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlaybackScreen({super.key, required this.video});

  @override
  State<VideoPlaybackScreen> createState() => _VideoPlaybackScreenState();
}

class _VideoPlaybackScreenState extends State<VideoPlaybackScreen> {
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    if (widget.video.isYouTube) {
      final videoId =
          YoutubePlayerController.convertUrlToId(widget.video.url) ??
              widget.video.url;
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: widget.video.isYouTube && _ytController != null
            ? YoutubePlayer(controller: _ytController!)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off,
                      size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text(
                    'Local video playback\nis not supported on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video.url,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
