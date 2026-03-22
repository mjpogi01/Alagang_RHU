import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

const _typeIcon = {'Article': Icons.description_outlined, 'Video': Icons.video_library_outlined, 'Guide': Icons.link};
const _typeColor = {'Article': AdminUI.indigo, 'Video': AdminUI.red, 'Guide': AdminUI.emerald};

final _mockResources = [
  ('Understanding Hypertension', 'Article', 'Heart Health', 'A comprehensive guide to managing high blood pressure through lifestyle changes.', '8 min read', true),
  ('Diabetes Prevention Tips', 'Video', 'Diabetes', 'Expert advice on preventing and managing Type 2 diabetes.', '12 min', false),
  ('Mental Wellness Toolkit', 'Guide', 'Mental Health', 'Practical tools and exercises for maintaining mental wellbeing.', '15 min read', true),
];

/// Admin: create and manage learning resources and modules for users.
class AdminLearningResourcesScreen extends StatefulWidget {
  const AdminLearningResourcesScreen({super.key, this.hideAppBar = false});

  final bool hideAppBar;

  @override
  State<AdminLearningResourcesScreen> createState() => _AdminLearningResourcesScreenState();
}

class _AdminLearningResourcesScreenState extends State<AdminLearningResourcesScreen> {
  final List<({String title, String type, String category, String description, String duration, bool featured})> _resources = List.from(_mockResources.map((e) => (title: e.$1, type: e.$2, category: e.$3, description: e.$4, duration: e.$5, featured: e.$6)));

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.hideAppBar) return body;
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'Learning Resources'),
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
              'Learning Resources',
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
                      Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...List.generate(_resources.length, (i) {
          final r = _resources[i];
          final color = _typeColor[r.type] ?? AdminUI.indigo;
          final icon = _typeIcon[r.type] ?? Icons.description_outlined;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                  child: Text(r.type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AdminUI.border, borderRadius: BorderRadius.circular(6)),
                                  child: Text(r.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary, fontSize: 11)),
                                ),
                                if (r.featured)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: AdminUI.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, size: 11, color: AdminUI.amber), const SizedBox(width: 4), Text('Featured', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminUI.amber))]),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(r.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AdminUI.textPrimary)),
                            const SizedBox(height: 4),
                            Text(r.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textSecondary, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(children: [Icon(Icons.schedule_outlined, size: 12, color: AdminUI.textTertiary), const SizedBox(width: 4), Text(r.duration, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary, fontSize: 11))]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit'), style: OutlinedButton.styleFrom(foregroundColor: AdminUI.indigo, side: const BorderSide(color: AdminUI.indigo))),
                      const SizedBox(width: 8),
                      TextButton.icon(onPressed: () => setState(() => _resources.removeAt(i)), icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: AdminUI.red)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
