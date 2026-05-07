import 'dart:html' as html;
import 'dart:typed_data';
import 'package:video_player/video_player.dart';

class VideoPickHelper {
  String? _blobUrl;

  VideoPlayerController controllerFromPick(
      {String? path, Uint8List? bytes}) {
    if (_blobUrl != null) html.Url.revokeObjectUrl(_blobUrl!);
    final blob = html.Blob([bytes!], 'video/mp4');
    _blobUrl = html.Url.createObjectUrlFromBlob(blob);
    return VideoPlayerController.networkUrl(Uri.parse(_blobUrl!));
  }

  void release() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
  }
}
