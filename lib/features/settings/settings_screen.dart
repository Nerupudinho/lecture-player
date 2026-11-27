import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/source_link.dart';
import '../agent/agent_setup_screen.dart';
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
    final url = await configDao.get(kSourceUrl) ?? '';
    final last = await configDao.get(kLastFetchedAt);
    if (mounted) {
      setState(() {
        _urlController.text = url;
        _lastFetched = last;
        _loadingConfig = false;
      });
    }
  }

  Future<void> _saveAndRefresh() async {
    final url = SourceLink.normalize(_urlController.text);
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a source URL first.')),
      );
      return;
    }
    await ref.read(configDaoProvider).set(kSourceUrl, url);
    _urlController.text = url;
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

  Future<void> _backToStarters() async {
    final config = ref.read(configDaoProvider);
    await config.set(kSourceUrl, '');
    await config.set(kStarterTopics, '');
    // No source left: the root shows the topic picker again.
    ref.invalidate(listSourceProvider);
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AgentSetupScreen())),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Connect my agent'),
                  ),
                ),
                const SizedBox(height: 24),
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
                  'A Google Sheet, Gist, GitHub file or raw CSV link. Leave '
                  'empty and use a starter list instead from below.',
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
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: isRefreshing ? null : _backToStarters,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Use a starter list instead'),
                ),
                const SizedBox(height: 24),
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
                    'Link,Title,Why,Minutes,Added\n\n'
                    'Link and Title are required.\n'
                    'Why and Minutes show under each title.\n'
                    'Added (YYYY-MM-DD) drives "updated" and "new".\n'
                    'Rows with Duplicate = TRUE are skipped.\n'
                    'Other columns are ignored.',
                    style: TextStyle(
                        fontFamily: 'monospace', fontSize: 12, height: 1.6),
                  ),
                ),
              ],
            ),
    );
  }
}
