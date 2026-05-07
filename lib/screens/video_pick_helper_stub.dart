import 'dart:io';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';

class VideoPickHelper {
  VideoPlayerController controllerFromPick(
      {String? path, Uint8List? bytes}) {
    return VideoPlayerController.file(File(path!));
  }

  void release() {}
}
