import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/agent_kit.dart';
import '../../services/list_check.dart';
import '../home/home_provider.dart';

/// "Make it yours": hand the playlist skill to your AI agent, then paste the
/// link it sends back. From then on the agent keeps the list fresh.
class AgentSetupScreen extends ConsumerStatefulWidget {
  /// Opened from "I already have a playlist link": skip to the link field.
  final bool startAtConnect;

  const AgentSetupScreen({super.key, this.startAtConnect = false});

  @override
  ConsumerState<AgentSetupScreen> createState() => _AgentSetupScreenState();
}

class _AgentSetupScreenState extends ConsumerState<AgentSetupScreen> {
  final _topics = TextEditingController();
  final _link = TextEditingController();
  bool _checking = false;
  ListCheckResult? _result;

  @override
  void initState() {
    super.initState();
    _prefillTopics();
  }

  Future<void> _prefillTopics() async {
    final source = await ref.read(listSourceProvider.future);
    if (source is StarterSource && mounted && _topics.text.isEmpty) {
      _topics.text = source.topics.map((t) => t.label).join(', ');
    }
  }

  List<String> get _topicList => _topics.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _share() async {
    final text = await AgentKit.message(_topicList);
    await Share.share(text, subject: 'Lecture Player playlist skill');
  }

  Future<void> _copy() async {
    final text = await AgentKit.message(_topicList);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Copied. Paste it into your agent\'s chat.')));
    }
  }

  Future<void> _pasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      // Agents often wrap the link in a sentence; keep just the URL.
      final url = RegExp(r'https?://\S+').firstMatch(text)?.group(0) ?? text;
      setState(() => _link.text = url.replaceAll(RegExp(r'[).,>]+$'), ''));
    }
  }

  Future<void> _connect() async {
    setState(() {
      _checking = true;
      _result = null;
    });
    final checker = ListCheck(
      fetch: ref.read(fetcherProvider).fetch,
      parser: ref.read(csvParserProvider),
    );
    final result = await checker.check(_link.text);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = result;
    });
    if (result.ok) {
      await ref
          .read(refreshStateProvider.notifier)
          .useOwnList(result.url, result.videos);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  void dispose() {
    _topics.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grey = TextStyle(color: Colors.grey.shade400, height: 1.4);
    return Scaffold(
      appBar: AppBar(title: const Text('Connect my list')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (!widget.startAtConnect) ...[
            Text(
              'Your AI agent (Claude, ChatGPT, Grok…) can build your list and '
              'add new talks every week. Two steps.',
              style: grey,
            ),
            const SizedBox(height: 24),
            const _StepTitle(number: 1, text: 'Give your agent the skill'),
            const SizedBox(height: 12),
            TextField(
              controller: _topics,
              decoration: const InputDecoration(
                labelText: 'What should it find for you?',
                hintText: 'e.g. product strategy, AI agents, fundraising',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.send),
                    label: const Text('Share to my agent'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'It sets up a public list file (a Gist, GitHub file or Google '
              'Sheet), fills it, schedules a weekly refresh, and replies with '
              'a link.',
              style: grey.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 32),
            const _StepTitle(number: 2, text: 'Paste the link it sends back'),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              'Paste the link to your list: a Google Sheet, Gist, GitHub file '
              'or raw CSV link.',
              style: grey,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _link,
            autofocus: widget.startAtConnect,
            keyboardType: TextInputType.url,
            autocorrect: false,
            onSubmitted: (_) => _connect(),
            decoration: InputDecoration(
              hintText: 'https://…',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link),
              suffixIcon: IconButton(
                tooltip: 'Paste',
                icon: const Icon(Icons.content_paste),
                onPressed: _pasteLink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _checking ? null : _connect,
              child: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Connect'),
            ),
          ),
          if (_result != null && !_result!.ok) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withAlpha(60),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade700),
              ),
              child: Text(_result!.message,
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final int number;
  final String text;
  const _StepTitle({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: scheme.primary,
          child: Text('$number',
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
