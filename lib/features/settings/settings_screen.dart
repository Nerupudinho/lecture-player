import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  String? _lastFetched;
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final configDao = ref.read(configDaoProvider);
    final url = await configDao.get('source_url') ?? '';
    final last = await configDao.get('last_fetched_at');
    if (mounted) {
      setState(() {
        _urlController.text = url;
        _lastFetched = last;
        _loadingConfig = false;
      });
    }
  }

  Future<void> _saveAndRefresh() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a source URL first.')),
      );
      return;
    }
    await ref.read(configDaoProvider).set('source_url', url);
    await ref.read(refreshStateProvider.notifier).refresh();

    if (mounted) {
      final refreshState = ref.read(refreshStateProvider);
      if (!refreshState.hasError) {
        _loadConfig();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist refreshed successfully!')),
        );
      }
    }
  }

  String _formatTimestamp(String? iso) {
    if (iso == null) return 'Never';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
          '${_pad(dt.hour)}:${_pad(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refreshState = ref.watch(refreshStateProvider);
    final isRefreshing = refreshState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loadingConfig
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Playlist Source URL',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText:
                        'https://raw.githubusercontent.com/<user>/<repo>/master/playlist/lectures.csv',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste the raw URL of your playlist CSV. The default lives at '
                  'raw.githubusercontent.com/Nerupudinho/lecture-player/master/'
                  'playlist/lectures.csv and is updated automatically. Any URL '
                  'serving the same CSV columns works.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isRefreshing ? null : _saveAndRefresh,
                    icon: isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh),
                    label: Text(
                        isRefreshing ? 'Refreshing...' : 'Save & Refresh Now'),
                  ),
                ),
                if (refreshState.hasError) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade700),
                    ),
                    child: Text(
                      refreshState.error.toString(),
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Last refreshed: ${_formatTimestamp(_lastFetched)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Playlist Format',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Link            | Title           | Duplicate\n'
                    'maven.com/p/... | Lecture title   | FALSE\n'
                    'lennysnews.../p | Podcast episode | FALSE\n'
                    'youtube.com/... | Another lecture | FALSE\n\n'
                    'Tracking links are decoded automatically.\n'
                    'Rows with Duplicate = TRUE are skipped.\n'
                    'Extra columns (Source, Added) are ignored.',
                    style: TextStyle(
                        fontFamily: 'monospace', fontSize: 12, height: 1.6),
                  ),
                ),
              ],
            ),
    );
  }
}
