/// A single bulletin board post (TikTok-style card).
class BulletinPost {
  const BulletinPost({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.tags = const [],
    this.createdAt,
    this.backgroundColor,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> tags;
  final DateTime? createdAt;
  final int? backgroundColor; // optional hex (e.g. 0xFF1A4F3E)

  String get dateLabel {
    if (createdAt == null) return '';
    final d = createdAt!;
    final months = [
      'Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo',
      'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
