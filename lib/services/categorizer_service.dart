/// Assigns a category to a lecture from keywords in its title.
///
/// First keyword match wins; falls back to [defaultCategory]. Rules mirror the
/// server-side `lectureCategorize` used by the Gmail sync script so the app and
/// the pipeline bucket titles the same way.
class CategorizerService {
  static const String defaultCategory = 'Uncategorized';

  // Ordered: earlier rules take precedence.
  static const List<MapEntry<String, List<String>>> _rules = [
    MapEntry('AI & Claude Code', [
      'claude', 'mcp', 'model context', 'anthropic', 'ai agent', 'llm',
      'cursor', 'notebooklm', 'gemini', 'openai', 'chatgpt', 'ai native',
      'ai pm', 'ai product', 'antigravity', 'openclaw', 'clawdbot', 'agentic',
    ]),
    MapEntry('Product Management', [
      'product manager', ' pm ', 'product sense', 'product leader',
      'product management', 'product strategy', 'roadmap', 'fractional',
      'hiring manager', 'interview pm', 'pm interview', 'cpo', 'promotion',
    ]),
    MapEntry('AI Tools & Automation', [
      'automation', 'zapier', 'make.com', 'n8n', 'workflow', 'apps script',
      'vscode', 'coding', 'developer', 'coding assistant', 'prototyp',
    ]),
    MapEntry('Finance & Investing', [
      'invest', 'stock', 'bitcoin', 'crypto', 'portfolio', 'wealth',
      'mutual fund', 'options', 'saas revenue', 'grow app', 'money', 'earning',
    ]),
    MapEntry('Productivity & Systems', [
      'habit', 'productivity', 'system', 'focus', 'deep work',
      'time management', 'second brain', 'file management', 'audience',
    ]),
    MapEntry('Fitness', [
      'workout', 'fitness', 'fat', 'exercise', 'gym', 'plank',
      'cortisol', 'belly fat', 'body',
    ]),
  ];

  String categorize(String title) {
    final lower = title.toLowerCase();
    for (final rule in _rules) {
      for (final keyword in rule.value) {
        if (lower.contains(keyword.toLowerCase())) return rule.key;
      }
    }
    return defaultCategory;
  }
}
