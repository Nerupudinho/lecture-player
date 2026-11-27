import 'package:flutter/services.dart' show rootBundle;

/// Builds the message a user hands to their AI agent (Claude, ChatGPT, Grok…):
/// a one-line ask plus the playlist skill, with their topics filled in.
class AgentKit {
  static const skillAsset = 'agent-kit/SKILL.md';

  static Future<String> message(List<String> topics) async =>
      compose(await rootBundle.loadString(skillAsset), topics);

  /// Pure part, kept separate so it can be unit-tested without assets.
  static String compose(String skill, List<String> topics) {
    final topicText = topics.isEmpty
        ? 'ask them, in one question, what they want to learn'
        : topics.join(', ');
    return 'Please set up and maintain my Lecture Player playlist using the '
        'skill below. When it is ready, reply with the link to the list so I '
        'can paste it into the app.\n\n'
        '${skill.replaceAll('{{TOPICS}}', topicText)}';
  }
}
