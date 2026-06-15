import 'dart:convert';
import 'dart:io' show zlib;

/// Resolves a (possibly tracking-wrapped) link to its clean, playable URL.
///
/// Maven emails wrap recording links in several tracking formats. The real
/// `maven.com/p/...` URL is recoverable offline by decoding — no need to
/// HTTP-follow the redirect (which would expire and leak a click):
///
///  - `*/e/c/<base64>/...`        -> base64 -> JSON, real URL in `href`
///    (email-courses.maven.com, email-list.maven.com)
///  - `link.courses.maven.com/c/<base64>` -> base64 -> zlib inflate ->
///    query string, real URL is the `l` param
///  - `*.kit-mail3.com/.../<base64>` (ConvertKit) -> last path segment
///    base64-decodes straight to the URL
///  - anything already clean (maven.com/p/, youtube.com, ...) passes through
///
/// Unknown formats fall back to the original string, which url_launcher can
/// still attempt to open.
class LinkDecoderService {
  String decode(String raw) {
    var url = raw.trim().replaceAll('​', '').replaceAll('﻿', '');
    if (url.isEmpty) return url;
    try {
      if (url.contains('kit-mail3.com') || url.contains('convertkit')) {
        final seg = url
            .split('?')
            .first
            .split('/')
            .where((s) => s.isNotEmpty)
            .last;
        final decoded = utf8.decode(_b64(seg));
        return decoded.startsWith('http') ? decoded : url;
      }
      if (url.contains('/e/c/')) {
        final blob = url.split('/e/c/')[1].split('/').first;
        final obj = jsonDecode(utf8.decode(_b64(blob)));
        final href = (obj is Map) ? obj['href'] : null;
        return (href is String && href.isNotEmpty) ? href : url;
      }
      if (url.contains('link.courses.maven.com/c/')) {
        final blob = url.split('/c/')[1].split('/').first;
        final inflated = utf8.decode(zlib.decode(_b64(blob)));
        final l = Uri.splitQueryString(inflated)['l'];
        return (l != null && l.isNotEmpty) ? l : url;
      }
      return url; // already clean
    } catch (_) {
      return url; // best-effort: still launchable
    }
  }

  /// Decodes base64 that may be standard or URL-safe, with or without padding.
  List<int> _b64(String s) {
    var t = s.replaceAll('-', '+').replaceAll('_', '/');
    final pad = t.length % 4;
    if (pad != 0) t += '=' * (4 - pad);
    return base64.decode(t);
  }
}
