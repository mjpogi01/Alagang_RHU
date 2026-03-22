import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

const _categoryColors = {
  'Event': AdminUI.indigo,
  'Health': AdminUI.emerald,
  'Benefits': AdminUI.amber,
  'Wellness': AdminUI.blue,
  'General': AdminUI.violet,
};

final _mockPosts = [
  ('Community Health Fair 2024', 'Join us for our annual health fair at Barangay Plaza. Free checkups and consultations available!', 'Event', 'Jun 15, 2024', true),
  ('New Vaccination Schedule', 'Updated vaccination schedule for Q3 2024. Please check with your healthcare provider.', 'Health', 'Jun 10, 2024', false),
  ('Senior Citizen Benefits Update', 'New benefits package available for senior citizens starting July 2024.', 'Benefits', 'Jun 5, 2024', true),
  ('Mental Health Awareness Month', 'Resources and support available throughout June. Reach out to our counselors.', 'Wellness', 'Jun 1, 2024', false),
];

/// Admin: edit bulletin board contents.
class AdminBulletinScreen extends StatefulWidget {
  const AdminBulletinScreen({super.key, this.hideAppBar = false});

  final bool hideAppBar;

  @override
  State<AdminBulletinScreen> createState() => _AdminBulletinScreenState();
}

class _AdminBulletinScreenState extends State<AdminBulletinScreen> {
  final List<({String title, String content, String category, String date, bool pinned})> _posts = List.from(_mockPosts.map((e) => (title: e.$1, content: e.$2, category: e.$3, date: e.$4, pinned: e.$5)));

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.hideAppBar) return body;
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'Bulletin Board'),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final pad = AppTheme.scale(context, AppTheme.spacingLg);
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + AppTheme.floatingNavBarClearance),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Bulletin Board',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AdminUI.textPrimary,
                  ),
            ),
            Material(
              color: AdminUI.indigo,
              borderRadius: BorderRadius.circular(AdminUI.radiusSm),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(AdminUI.radiusSm),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Add Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...List.generate(_posts.length, (i) {
          final p = _posts[i];
          final color = _categoryColors[p.category] ?? AdminUI.indigo;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AdminCard(
              padding: EdgeInsets.zero,
              borderColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AdminUI.radiusLg),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: color),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text(p.category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                                  ),
                                  if (p.pinned) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AdminUI.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.push_pin, size: 11, color: AdminUI.amber), const SizedBox(width: 4), Text('Pinned', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminUI.amber))]),
                                    ),
                                  ],
                                  const Spacer(),
                                  IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: AdminUI.textTertiary), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                                  IconButton(icon: Icon(Icons.delete_outline, size: 18, color: AdminUI.red), onPressed: () => setState(() => _posts.removeAt(i)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(p.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AdminUI.textPrimary)),
                              const SizedBox(height: 4),
                              Text(p.content, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text('by Admin · ${p.date}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
