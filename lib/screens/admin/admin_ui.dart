import 'package:flutter/material.dart';

/// Admin-only design tokens inspired by `AlagangRHU_AdminApp.jsx`.
class AdminUI {
  AdminUI._();

  static const Color bg = Color(0xFFF8FAFC); // slate-50
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFF1F5F9); // slate-100

  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color textTertiary = Color(0xFF94A3B8); // slate-400

  static const Color indigo = Color(0xFF6366F1);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF3B82F6);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color rose = Color(0xFFEC4899);
  static const Color red = Color(0xFFEF4444);
  static const Color teal = Color(0xFF14B8A6);

  /// Admin bottom nav bar (white theme, light purple pill for selected tab).
  static const Color navBarBg = Color(0xFFFFFFFF);
  static const Color navBarInactive = Color(0xFF94A3B8);
  static const Color navBarPillBg = Color(0xFFE0E7FF); // indigo-100
  static const Color navBarPillFg = Color(0xFF6366F1);  // indigo-500

  static const double radiusLg = 16;
  static const double radiusMd = 12;
  static const double radiusSm = 10;

  static List<BoxShadow> cardShadow({double opacity = 0.06}) => [
        BoxShadow(
          color: Colors.black.withOpacity(opacity),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: borderColor ?? Colors.transparent, width: 1.5),
        boxShadow: cardShadow(),
      );

  static Widget iconPill({
    required IconData icon,
    required Color color,
    double size = 18,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      child: Icon(icon, size: size, color: color),
    );
  }
}

/// Bottom nav bar: white theme, nav items, selected item in light purple pill.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<({String label, IconData icon})> items = [
    (label: 'Home', icon: Icons.grid_view_rounded),
    (label: 'Services', icon: Icons.medical_services_outlined),
    (label: 'Facilities', icon: Icons.local_hospital_outlined),
    (label: 'Calendar', icon: Icons.calendar_today_outlined),
    (label: 'Bulletin', icon: Icons.description_outlined),
    (label: 'More', icon: Icons.more_horiz),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminUI.navBarBg,
        border: Border(top: BorderSide(color: AdminUI.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = currentIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AdminUI.navBarPillBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: selected ? AdminUI.navBarPillFg : AdminUI.navBarInactive,
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminUI.navBarPillFg,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = true,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;
  /// If set, shown on the left instead of back button (e.g. logo/health icon).
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 14);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: AdminUI.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: leading == null && showBack && canPop,
      leading: leading,
      titleSpacing: (leading != null || (showBack && canPop)) ? 0 : 16,
      title: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AdminUI.textPrimary,
                    letterSpacing: -0.2,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminUI.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AdminUI.border),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AdminUI.cardDecoration(borderColor: borderColor),
      child: Material(
        color: Colors.transparent,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Reusable row of action buttons: Edit, Archive/Unarchive, Delete.
/// Use for categories and services (and other list rows) in admin screens.
class AdminRowActions extends StatelessWidget {
  const AdminRowActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.onArchive,
    this.onUnarchive,
    this.isArchived = false,
    this.iconSize = 20,
    this.compact = false,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final bool isArchived;
  final double iconSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 18.0 : iconSize;
    final minSize = compact ? 32.0 : 40.0;
    final padding = compact ? EdgeInsets.zero : null;
    final constraints = BoxConstraints(minWidth: minSize, minHeight: minSize);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_outlined, size: size, color: AdminUI.textTertiary),
          onPressed: onEdit,
          padding: padding ?? EdgeInsets.zero,
          constraints: constraints,
        ),
        if (onArchive != null || onUnarchive != null)
          IconButton(
            icon: Icon(
              isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              size: size,
              color: AdminUI.amber,
            ),
            onPressed: isArchived ? onUnarchive : onArchive,
            padding: padding ?? EdgeInsets.zero,
            constraints: constraints,
          ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: size, color: AdminUI.red),
          onPressed: onDelete,
          padding: padding ?? EdgeInsets.zero,
          constraints: constraints,
        ),
      ],
    );
  }
}

