/// Social channels for "Share SmartBudget": each one's web share link and the
/// tone of message that fits it. Pure Dart so it is unit-testable.
library;

enum ShareChannel {
  whatsapp,
  telegram,
  x,
  facebook,
  linkedin,
  instagram,
  email,
  sms,
}

/// Message style per channel: a friendly note for chats, a short post for X,
/// a professional post for LinkedIn.
enum ShareTone { personal, short, professional }

class SharePayload {
  const SharePayload({
    required this.text,
    required this.link,
    this.subject = '',
  });

  final String text;
  final String link;
  final String subject;

  String get textWithLink => '$text\n$link';
}

abstract final class ShareLinks {
  static ShareTone toneOf(ShareChannel channel) => switch (channel) {
        ShareChannel.x => ShareTone.short,
        ShareChannel.linkedin => ShareTone.professional,
        _ => ShareTone.personal,
      };

  /// Channels whose share page ignores pre-filled text (or that have no web
  /// share page at all): the caption goes to the clipboard so the user can
  /// paste it into the post.
  static bool copiesCaption(ShareChannel channel) =>
      channel == ShareChannel.facebook ||
      channel == ShareChannel.linkedin ||
      channel == ShareChannel.instagram;

  /// The link that opens [channel]'s share composer, or null for Instagram
  /// (it has no web share link; the app saves an image instead).
  static Uri? uri(ShareChannel channel, SharePayload p) => switch (channel) {
        ShareChannel.whatsapp =>
          _build('https://wa.me/', <String, String>{'text': p.textWithLink}),
        ShareChannel.telegram => _build('https://t.me/share/url',
            <String, String>{'url': p.link, 'text': p.text}),
        ShareChannel.x => _build('https://x.com/intent/tweet',
            <String, String>{'text': p.text, 'url': p.link}),
        ShareChannel.facebook => _build(
            'https://www.facebook.com/sharer/sharer.php',
            <String, String>{'u': p.link}),
        ShareChannel.linkedin => _build(
            'https://www.linkedin.com/sharing/share-offsite/',
            <String, String>{'url': p.link}),
        ShareChannel.email => _build('mailto:', <String, String>{
            'subject': p.subject,
            'body': p.textWithLink,
          }),
        // `sms:?&body=` is the form both Android and iOS accept.
        ShareChannel.sms => Uri.parse(
            'sms:?&body=${Uri.encodeComponent(p.textWithLink)}'),
        ShareChannel.instagram => null,
      };

  // Percent-encodes spaces as %20 (not '+'), which mailto: and every share
  // endpoint decode the same way.
  static Uri _build(String base, Map<String, String> query) {
    final String q = query.entries
        .map((MapEntry<String, String> e) =>
            '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return Uri.parse('$base?$q');
  }
}
