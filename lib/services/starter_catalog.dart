/// Curated starter lists bundled with the app (see `starter/*.csv`).
///
/// They give a brand-new user something worth watching on first launch,
/// before any agent has run. Every item is a public, free link.
class StarterTopic {
  final String id;
  final String label;
  final String blurb;

  const StarterTopic(this.id, this.label, this.blurb);

  String get assetPath => 'starter/$id.csv';
}

class StarterCatalog {
  static const topics = <StarterTopic>[
    StarterTopic('product', 'Product', 'Discovery, strategy, PM craft'),
    StarterTopic('ai', 'AI', 'LLMs, agents, building with AI'),
    StarterTopic('startups', 'Startups', 'Founders, fundraising, growth'),
    StarterTopic('engineering', 'Engineering', 'System design and craft'),
  ];

  static StarterTopic? byId(String id) {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Stored in config as a comma-separated list of topic ids.
  static List<StarterTopic> decode(String? stored) => (stored ?? '')
      .split(',')
      .map((s) => byId(s.trim()))
      .whereType<StarterTopic>()
      .toList();

  static String encode(Iterable<StarterTopic> topics) =>
      topics.map((t) => t.id).join(',');
}
