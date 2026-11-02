import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nawa Music',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PlayerHomePage(),
    );
  }
}

class Track {
  const Track({
    required this.title,
    required this.artist,
    required this.url,
    required this.durationLabel,
  });

  final String title;
  final String artist;
  final String url;
  final String durationLabel;
}

class PlayerHomePage extends StatefulWidget {
  const PlayerHomePage({super.key});

  @override
  State<PlayerHomePage> createState() => _PlayerHomePageState();
}

class _PlayerHomePageState extends State<PlayerHomePage> {
  final AudioPlayer _player = AudioPlayer();
  int _currentIndex = 0;
  bool _loading = false;
  String? _error;
  double _volume = 1;
  double _speed = 1;

  // Demo audio URLs. Replace these with URLs returned by your own backend.
  final List<Track> _tracks = const [
    Track(
      title: 'SoundHelix Song 1',
      artist: 'Demo Artist',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      durationLabel: 'Demo',
    ),
    Track(
      title: 'SoundHelix Song 2',
      artist: 'Demo Artist',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      durationLabel: 'Demo',
    ),
    Track(
      title: 'SoundHelix Song 3',
      artist: 'Demo Artist',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      durationLabel: 'Demo',
    ),
  ];

  Track get _currentTrack => _tracks[_currentIndex];

  @override
  void initState() {
    super.initState();
    _configureAudioSession();
    _loadTrack(0, autoplay: false);
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      if (mounted) setState(() => _error = 'Audio session: $e');
    }
  }

  Future<void> _loadTrack(int index, {bool autoplay = true}) async {
    if (index < 0 || index >= _tracks.length) return;
    setState(() {
      _currentIndex = index;
      _loading = true;
      _error = null;
    });
    try {
      await _player.setUrl(_tracks[index].url);
      if (autoplay) await _player.play();
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تشغيل المقطع. تحقق من الإنترنت أو الرابط.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> _next() async {
    await _loadTrack((_currentIndex + 1) % _tracks.length);
  }

  Future<void> _previous() async {
    final position = _player.position;
    if (position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    await _loadTrack((_currentIndex - 1 + _tracks.length) % _tracks.length);
  }

  String _time(Duration? value) {
    final duration = value ?? Duration.zero;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NAWA MUSIC', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'معلومات',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Nawa Music',
              applicationVersion: 'Stage 3 - Audio Player',
              children: const [Text('مشغل تجريبي حقيقي باستخدام just_audio.')],
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Expanded(
              child: Center(
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D5DFB), Color(0xFF182B55), Color(0xFF111827)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x665E50D8), blurRadius: 45, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, size: 112, color: Colors.white),
                ),
              ),
            ),
            Text(_currentTrack.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_currentTrack.artist, style: TextStyle(color: Colors.white.withValues(alpha: .65))),
            const SizedBox(height: 18),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<Duration?>(
                stream: _player.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
                      final value = position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
                      return Column(
                        children: [
                          Slider(
                            value: value,
                            min: 0,
                            max: maxMs,
                            onChanged: duration == Duration.zero
                                ? null
                                : (v) => _player.seek(Duration(milliseconds: v.round())),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_time(position), style: const TextStyle(color: Colors.white60)),
                              Text(_time(duration), style: const TextStyle(color: Colors.white60)),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: _previous, icon: const Icon(Icons.skip_previous_rounded), iconSize: 42),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: FilledButton(
                        onPressed: _loading ? null : _togglePlayback,
                        style: FilledButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
                        child: _loading
                            ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 42),
                      ),
                    ),
                    const SizedBox(width: 18),
                    IconButton(onPressed: _next, icon: const Icon(Icons.skip_next_rounded), iconSize: 42),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
              child: Row(
                children: [
                  const Icon(Icons.volume_down_rounded, color: Colors.white60),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        _player.setVolume(v);
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded, color: Colors.white60),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded, color: Colors.white60),
                  const SizedBox(width: 12),
                  const Text('سرعة التشغيل'),
                  const Spacer(),
                  DropdownButton<double>(
                    value: _speed,
                    items: const [
                      DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                      DropdownMenuItem(value: 1, child: Text('1.0x')),
                      DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                      DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                      DropdownMenuItem(value: 2, child: Text('2.0x')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _speed = v);
                      _player.setSpeed(v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Row(
                children: [
                  const Text('قائمة التشغيل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${_tracks.length} مقاطع', style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: _tracks.length,
                itemBuilder: (context, index) {
                  final track = _tracks[index];
                  final selected = index == _currentIndex;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: selected ? const Color(0xFF7667F8) : const Color(0xFF202943),
                      child: Icon(selected ? Icons.equalizer_rounded : Icons.music_note_rounded),
                    ),
                    title: Text(track.title, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(track.artist),
                    trailing: selected ? const Icon(Icons.volume_up_rounded, color: Color(0xFF9B8FFF)) : null,
                    onTap: () => _loadTrack(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
