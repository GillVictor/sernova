/// Row of EP-109 (assumed `{id, content, read, createdAt}`, OP-25; dictionary
/// attributes contenu, lue, date).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.content,
    required this.read,
    this.createdAt,
  });

  final String id;
  final String content;
  final bool read;
  final DateTime? createdAt;

  AppNotification asRead() =>
      AppNotification(id: id, content: content, read: true, createdAt: createdAt);

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        content: (j['content'] as String?) ?? '',
        read: (j['read'] as bool?) ?? false,
        createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? ''),
      );
}
