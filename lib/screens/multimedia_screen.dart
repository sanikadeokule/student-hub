import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'video_pick_helper_stub.dart'
    if (dart.library.html) 'video_pick_helper_web.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../services/video_service.dart';
import '../services/subject_service.dart';
import '../models/subject_model.dart';

class MultimediaScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MultimediaScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<MultimediaScreen> createState() => _MultimediaScreenState();
}

class _MultimediaScreenState extends State<MultimediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multimedia'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: 'Audio'),
            Tab(icon: Icon(Icons.videocam), text: 'Video'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AudioPlayerTab(),
          VideoPlayerTab(),
        ],
      ),
    );
  }
}

//// ===================== AUDIO PLAYER =====================

class AudioPlayerTab extends StatefulWidget {
  const AudioPlayerTab({super.key});

  @override
  State<AudioPlayerTab> createState() => _AudioPlayerTabState();
}

class _AudioPlayerTabState extends State<AudioPlayerTab> {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final List<Map<String, String>> _playlist = [
    {
      'title': 'Focus Music',
      'artist': 'Study Beats',
      'url':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
    },
    {
      'title': 'Lo-Fi Chill',
      'artist': 'Study Vibes',
      'url':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'
    },
    {
      'title': 'Deep Focus',
      'artist': 'Ambient',
      'url':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'
    },
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _player.positionStream.listen((p) {
      setState(() => _position = p);
    });

    _player.durationStream.listen((d) {
      setState(() => _duration = d ?? Duration.zero);
    });

    _player.playerStateStream.listen((s) {
      setState(() => _isPlaying = s.playing);
    });
  }

  Future<void> _loadAndPlay(int index) async {
    setState(() => _currentIndex = index);
    await _player.setUrl(_playlist[index]['url']!);
    await _player.play();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final track = _playlist[_currentIndex];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBg : kLightBg;
    final cardBg  = isDark ? kDarkCard : Colors.white;
    final textPrimary = isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF2A2A3D);
    final textSub     = isDark ? Colors.white54 : Colors.grey[600]!;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kMint],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("My Music 🎧",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      Text("Feel the Beat",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: kPrimary),
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// TRENDING
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Trending Now",
                  style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ),

            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _playlist.length,
                itemBuilder: (context, index) {
                  final trendAccents = [kPrimary, kMint, kAmber];
                  final accent = trendAccents[index % trendAccents.length];
                  return GestureDetector(
                    onTap: () => _loadAndPlay(index),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: cardBg,
                        border: Border.all(color: accent.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accent.withOpacity(0.7), accent.withOpacity(0.4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            ),
                            child: Center(child: Icon(Icons.music_note, size: 40, color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                            child: Text(_playlist[index]['title']!,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                          Text(_playlist[index]['artist']!,
                              style: TextStyle(color: textSub, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// NOW PLAYING
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary.withOpacity(0.8), kMint.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.music_note, size: 80, color: Colors.white),
                    ),

                    const SizedBox(height: 20),

                    Text(track['title']!,
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),

                    const SizedBox(height: 4),
                    Text(track['artist']!,
                        style: TextStyle(color: textSub, fontSize: 14)),

                    const SizedBox(height: 20),

                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: kPrimary,
                        inactiveTrackColor: kPrimary.withOpacity(0.2),
                        thumbColor: kPrimary,
                        overlayColor: kPrimary.withOpacity(0.15),
                      ),
                      child: Slider(
                        value: _position.inSeconds.toDouble(),
                        max: _duration.inSeconds.toDouble() == 0
                            ? 1
                            : _duration.inSeconds.toDouble(),
                        onChanged: (v) =>
                            _player.seek(Duration(seconds: v.toInt())),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(_position),
                            style: TextStyle(color: textSub, fontSize: 12)),
                        Text(_format(_duration),
                            style: TextStyle(color: textSub, fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.skip_previous_rounded, color: textPrimary, size: 32),
                          onPressed: () {
                            if (_currentIndex > 0) {
                              _loadAndPlay(_currentIndex - 1);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [kPrimary, Color(0xFFB3B7FF)]),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 35,
                            ),
                            onPressed: () => _isPlaying
                                ? _player.pause()
                                : _loadAndPlay(_currentIndex),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.skip_next_rounded, color: textPrimary, size: 32),
                          onPressed: () {
                            if (_currentIndex < _playlist.length - 1) {
                              _loadAndPlay(_currentIndex + 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//// ===================== VIDEO PLAYER =====================

class VideoPlayerTab extends StatefulWidget {
  const VideoPlayerTab({super.key});

  @override
  State<VideoPlayerTab> createState() => _VideoPlayerTabState();
}

class _VideoPlayerTabState extends State<VideoPlayerTab> {
  VideoPlayerController? _controller;
  bool _isLoaded = false;
  final _videoPick = VideoPickHelper();

  // YouTube
  final TextEditingController _youtubeUrlController = TextEditingController();
  final TextEditingController _videoTitleController = TextEditingController();
  YoutubePlayerController? _youtubeController;

  final VideoService _videoService = VideoService();
  final SubjectService _subjectService = SubjectService();
  String? _selectedSubjectId;

  @override
  void dispose() {
    _controller?.dispose();
    _youtubeController?.close();
    _youtubeUrlController.dispose();
    _videoTitleController.dispose();
    _videoPick.release();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;

    _controller?.dispose();
    setState(() => _isLoaded = false);

    _controller = _videoPick.controllerFromPick(
      path: result.files.first.path,
      bytes: result.files.first.bytes,
    )..initialize().then((_) {
        setState(() => _isLoaded = true);
      });
  }

  Future<void> _loadNetworkVideo() async {
    _controller?.dispose();
    setState(() => _isLoaded = false);

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
    )..initialize().then((_) {
        setState(() => _isLoaded = true);
      });
  }

  void _playYoutubeVideo() {
    final url = _youtubeUrlController.text.trim();
    final videoId = YoutubePlayerController.convertUrlToId(url);

    if (videoId != null) {
      _youtubeController?.close();

      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
        ),
      );

      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube URL')),
      );
    }
  }

  Future<void> _saveYoutubeVideo() async {
    final url = _youtubeUrlController.text.trim();
    final title = _videoTitleController.text.trim();

    if (url.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and URL')),
      );
      return;
    }

    final videoId = YoutubePlayerController.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube URL')),
      );
      return;
    }

    try {
      await _videoService.saveVideo(
        title: title,
        url: url,
        type: 'youtube',
        subjectId: _selectedSubjectId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video saved successfully!')),
      );

      _videoTitleController.clear();
      _youtubeUrlController.clear();
      setState(() => _selectedSubjectId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // YouTube Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YouTube Video Player & Saver',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _videoTitleController,
                    decoration: InputDecoration(
                      hintText: 'Video title...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<SubjectModel>>(
                    stream: _subjectService.getSubjects(),
                    builder: (context, snapshot) {
                      final subjects = snapshot.data ?? [];
                      return DropdownButtonFormField<String?>(
                        value: _selectedSubjectId,
                        decoration: InputDecoration(
                          hintText: 'Link to subject (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No subject'),
                          ),
                          ...subjects.map((subject) => DropdownMenuItem<String?>(
                            value: subject.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: subject.getColor(),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(subject.name),
                              ],
                            ),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedSubjectId = value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _youtubeUrlController,
                    decoration: InputDecoration(
                      hintText: 'Paste YouTube link...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _youtubeUrlController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _playYoutubeVideo,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveYoutubeVideo,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMint,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // YouTube Player
          if (_youtubeController != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: YoutubePlayer(
                  controller: _youtubeController!,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Local Video Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local Videos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadNetworkVideo,
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('Sample Video'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Pick Video'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Local Video Player
          if (_isLoaded && _controller != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                    const SizedBox(height: 12),
                    VideoProgressIndicator(_controller!, allowScrubbing: true),
                    const SizedBox(height: 12),
                    IconButton(
                      icon: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 48,
                      ),
                      onPressed: () => setState(() =>
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play()),
                    ),
                  ],
                ),
              ),
            )
          else if (!_isLoaded)
            const Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text("Load a video to start playing")),
              ),
            ),
        ],
      ),
    );
  }
}