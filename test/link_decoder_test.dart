import 'package:flutter_test/flutter_test.dart';
import 'package:lecture_player/services/link_decoder_service.dart';

void main() {
  final decoder = LinkDecoderService();

  test('email-courses /e/c/ link decodes to clean maven.com URL', () {
    const wrapped =
        'https://email-courses.maven.com/e/c/eyJlbWFpbF9pZCI6IlJNLXdCd1VBQVp3a2R1ZHA0VjNLTzU1aHU0RXpnUT09IiwiaHJlZiI6Imh0dHBzOi8vbWF2ZW4uY29tL3AvZDY3OWI5P3V0bV9zb3VyY2U9bWF2ZW5cdTAwMjZ1dG1fbWVkaXVtPWVtYWlsXHUwMDI2dXRtX2NhbXBhaWduPWNsY19jb2hvcnRfb3Blblx1MDAyNmFqc191aWQ9MTU3MTE5IiwiaW50ZXJuYWwiOiJjZmIwMDcxNGM4YjcwMTg5ODcyNiJ9/fbbb87410ad06cde7f3b77ed9618014cc502672164d9d09a8cd19217dc942f6d';
    final r = decoder.decode(wrapped);
    expect(r, startsWith('https://maven.com/p/d679b9'));
  });

  test('email-list /e/c/ link decodes to clean maven.com URL', () {
    const wrapped =
        'https://email-list.maven.com/e/c/eyJlbWFpbF9pZCI6ImRnVFBzQWNCQUltSEpvaUhKZ0dkSVYzZ2FzZkd5NlJJMGJ1TmFuRT0iLCJocmVmIjoiaHR0cHM6Ly9tYXZlbi5jb20vcC9mNmQ1NDIvYWktcG93ZXJlZC1wcm9kdWN0LXNraWxscy1mb3ItZXhlY3V0aXZlLWxlYWRlcnMtZ21zP2VtYWlsPWF0bXVyaS5zYWlnYW5lc2glNDBnbWFpbC5jb21cdTAwMjZ1dG1fbWVkaXVtPWVtYWlsX2xsX3Bvc3RfcmVjb3JkaW5nX2xpbmtcdTAwMjZhanNfdWlkPTE1NzExOSIsImludGVybmFsIjoiY2ZiMDA3MTRjOGI3MDE4OTg3MjYiLCJsaW5rX2lkIjoyOTk5OH0/d61fb6';
    final r = decoder.decode(wrapped);
    expect(r, startsWith('https://maven.com/p/f6d542/'));
  });

  test('link.courses /c/ zlib link decodes via l= query param', () {
    const wrapped =
        'https://link.courses.maven.com/c/eJw8kM2unSAURp8GZxj-RBwwaHLja5gtbI-kKIYNJ-nbN_eeptO1vsn6QumVcEvRSymnZYjeRCH3aUAv51k7s0xGDnhBylvIQOT3WiAGoPaPtj8PegpnKXnLCJEGvN_bx_Weon9qieMScLHHYfhhD-BGK8FBhp3DpFxwys5Sh-H0czgW4YyQ0iorcNoXKbWYHcxOKRn1kLwSygotnZwmNy0jRqXdZLQ90M1W7syITxONF7zxHkO5hkTbUcu1_RC_QiYcsj9be4jpX0ytTK3_10ytD1OrleEwiql17ylHDi-8Wwocnod4p3S_eMjQI_JQIvK9lBbgeni6j8IJiVK5mV57u7YLY-oX0185b3RCxS2n-zdT9ltS6TUg01_pplZ7aKUO1UO7ek0jQXrBjXQyI17fj_7UvL36GwAA__8eVpCp';
    final r = decoder.decode(wrapped);
    expect(r, startsWith('https://maven.com/p/61cf42/'));
  });

  test('ConvertKit kit-mail3 link decodes from last path segment', () {
    const wrapped =
        'https://2dc2944a.click.kit-mail3.com/5quq7xvxm3a7hn2nx0da6h9lqq4v0fnhrmn6o/6qheh8hlre97prso/aHR0cHM6Ly9tYXZlbi5jb20vcC81MmRjZTMvYW5hbHl0aWNhbC10aGlua2luZy1pbnRlcnZpZXdzLXdvcmxkLWNsYXNzLXByZXBhcmF0aW9uP3V0bV9tZWRpdW09bGxfc2hhcmVfbGluayZ1dG1fc291cmNlPWluc3RydWN0b3I=';
    final r = decoder.decode(wrapped);
    expect(r, startsWith('https://maven.com/p/52dce3/'));
  });

  test('already-clean maven.com URL passes through unchanged', () {
    const clean = 'https://maven.com/p/56fe68/build-for-chat-gpt-s-new-app-store';
    expect(decoder.decode(clean), clean);
  });

  test('already-clean youtube URL passes through unchanged', () {
    const clean = 'https://www.youtube.com/watch?v=RP4vJeIb7WU';
    expect(decoder.decode(clean), clean);
  });

  test('zero-width chars are stripped before decoding', () {
    const clean = '​https://maven.com/p/51e059/earning-manager-sponsorship​';
    expect(decoder.decode(clean),
        'https://maven.com/p/51e059/earning-manager-sponsorship');
  });

  test('unknown format falls back to the original string', () {
    const other = 'https://updates.vellum.ai/e3t/Ctc/abc123';
    expect(decoder.decode(other), other);
  });
}
