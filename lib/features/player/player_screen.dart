import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/video_model.dart';
import '../../shared/shuffle_service.dart';

/// Launches the video URL in the YouTube app (or browser as fallback),
/// then shows a minimal screen with a "Next Shuffle" button.
class PlayerScreen extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel> playlist;
  final ShuffleService shuffleService;

  const PlayerScreen({
    super.key,
    required this.video,
    required this.playlist,
    required this.shuffleService,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoModel _current;

  @override
  void initState() {
    super.initState();
    _current = widget.video;
    _launch(_current.url);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }

  void _nextShuffle() {
    final next = widget.shuffleService.nextRandom(widget.playlist);
    if (next != null) {
      setState(() => _current = next);
      _launch(next.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_current.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _current.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Opened externally',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _launch(_current.url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Reopen'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _nextShuffle,
                icon: const Icon(Icons.skip_next),
                label: const Text('Next Shuffle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
