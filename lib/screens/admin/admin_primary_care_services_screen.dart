import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

/// Icon name (stored in DB) -> IconData for admin and user UI.
const Map<String, IconData> _iconNameToIcon = {
  'group_outlined': Icons.group_outlined,
  'monitor_heart_outlined': Icons.monitor_heart_outlined,
  'favorite_border': Icons.favorite_border,
  'timelapse_outlined': Icons.timelapse_outlined,
  'vaccines_outlined': Icons.vaccines_outlined,
  'description_outlined': Icons.description_outlined,
  'local_hospital_outlined': Icons.local_hospital_outlined,
  'healing_outlined': Icons.healing_outlined,
};

const List<String> _iconNames = [
  'group_outlined',
  'monitor_heart_outlined',
  'favorite_border',
  'timelapse_outlined',
  'vaccines_outlined',
  'description_outlined',
  'local_hospital_outlined',
  'healing_outlined',
];

/// Admin: manage primary care categories and their services (for Service Directory).
class AdminPrimaryCareServicesScreen extends StatefulWidget {
  const AdminPrimaryCareServicesScreen({super.key, this.hideAppBar = false});

  final bool hideAppBar;

  @override
  State<AdminPrimaryCareServicesScreen> createState() =>
      _AdminPrimaryCareServicesScreenState();
}

class _AdminPrimaryCareServicesScreenState
    extends State<AdminPrimaryCareServicesScreen> {
  bool _loading = true;
  String? _error;
  bool _showArchived = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = SupabaseService.client;
      final catRes = await client
          .from('primary_care_categories')
          .select()
          .order('sort_order', ascending: true);
      final svcRes = await client.from('primary_care_services').select();
      final catList = List<Map<String, dynamic>>.from(catRes as List);
      final svcList = List<Map<String, dynamic>>.from(svcRes as List);
      if (!mounted) return;
      setState(() {
        _categories = catList;
        _services = svcList;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _categoriesVisible() {
    if (_showArchived) return _categories;
    return _categories.where((c) => c['archived_at'] == null).toList();
  }

  List<Map<String, dynamic>> _servicesForCategory(String categoryId) {
    final list = _services
        .where((s) => s['category_id'] == categoryId && (_showArchived || s['archived_at'] == null))
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    list.sort((a, b) =>
        ((a['sort_order'] as int?) ?? 0).compareTo((b['sort_order'] as int?) ?? 0));
    return list;
  }

  bool _isCategoryArchived(Map<String, dynamic> cat) =>
      cat['archived_at'] != null;
  bool _isServiceArchived(Map<String, dynamic> svc) =>
      svc['archived_at'] != null;

  /// True if service has no price or price is 0.
  static bool _isFree(Map<String, dynamic> svc) {
    final p = svc['price'];
    if (p == null) return true;
    if (p is num) return p <= 0;
    final n = num.tryParse(p.toString().trim());
    return n == null || n <= 0;
  }

  /// Label for badge: "Free" or "₱X" (formatted price).
  static String _priceBadgeLabel(Map<String, dynamic> svc) {
    if (_isFree(svc)) return 'Free';
    final p = svc['price'];
    if (p is num) return '₱${p.toStringAsFixed(p.truncateToDouble() == p ? 0 : 2)}';
    final n = num.tryParse(p.toString().trim());
    return (n != null && n > 0) ? '₱$n' : 'Free';
  }

  Color _colorFromHex(String hex) {
    String h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.hideAppBar) return body;
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'Primary Care Services'),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final pad = AppTheme.scale(context, AppTheme.spacingLg);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AdminUI.red)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            pad, pad, pad, pad + AppTheme.floatingNavBarClearance),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Categories & Services',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, color: AdminUI.textPrimary),
              ),
              Material(
                color: AdminUI.indigo,
                borderRadius: BorderRadius.circular(AdminUI.radiusSm),
                child: InkWell(
                  onTap: () => _showAddOrEditCategory(context),
                  borderRadius: BorderRadius.circular(AdminUI.radiusSm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Add category',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_showArchived)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Showing archived'),
                    selected: true,
                    onSelected: (_) => setState(() => _showArchived = false),
                    selectedColor: AdminUI.amber.withOpacity(0.2),
                  ),
                ],
              ),
            )
          else if (_categories.any((c) => c['archived_at'] != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilterChip(
                label: const Text('Show archived'),
                selected: false,
                onSelected: (_) => setState(() => _showArchived = true),
              ),
            ),
          if (_categoriesVisible().isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _showArchived
                      ? 'No archived categories.'
                      : 'No categories yet. Tap "Add category" to create one.',
                  style: TextStyle(color: AdminUI.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...List.generate(_categoriesVisible().length, (i) {
              final cat = _categoriesVisible()[i];
              final catId = cat['id'] as String?;
              final svcs = catId != null ? _servicesForCategory(catId) : <Map<String, dynamic>>[];
              return _CategoryCard(
                category: cat,
                services: svcs,
                colorFromHex: _colorFromHex,
                iconData: _iconNameToIcon[cat['icon_name'] as String?] ?? Icons.medical_services_outlined,
                isCategoryArchived: _isCategoryArchived(cat),
                onEditCategory: () => _showAddOrEditCategory(context, existing: cat),
                onArchiveCategory: () => _confirmArchiveCategory(context, cat),
                onUnarchiveCategory: () => _unarchiveCategory(cat),
                onDeleteCategory: () => _confirmDeleteCategory(context, cat),
                onAddService: () => _showAddOrEditService(context, categoryId: catId!),
                onEditService: (svc) => _showAddOrEditService(context, existing: svc),
                onArchiveService: (svc) => _archiveService(svc),
                onUnarchiveService: (svc) => _unarchiveService(svc),
                onDeleteService: (svc) => _confirmDeleteService(context, svc),
                isServiceArchived: _isServiceArchived,
                isServiceFree: _isFree,
                priceBadgeLabel: _priceBadgeLabel,
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showAddOrEditCategory(BuildContext context,
      {Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?['title'] as String? ?? '');
    final colorHexCtrl = TextEditingController(
        text: (existing?['color_hex'] as String?)?.replaceFirst('#', '') ?? 'BBDEFB');
    final sortOrder = (existing?['sort_order'] as int?) ?? _categories.length;
    final sortOrderCtrl = TextEditingController(text: sortOrder.toString());
    int iconIndex = _iconNames.indexOf(existing?['icon_name'] as String? ?? 'monitor_heart_outlined');
    if (iconIndex < 0) iconIndex = 0;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: AdminUI.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd), borderSide: const BorderSide(color: AdminUI.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd), borderSide: const BorderSide(color: AdminUI.indigo, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AdminUI.textSecondary),
      hintStyle: const TextStyle(color: AdminUI.textTertiary),
    );

    // Pop dialog with form data first (no async in button), then save in caller.
    // This avoids popping the admin route if the dialog was already dismissed.
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit category' : 'Add category'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: inputDecoration.copyWith(labelText: 'Title', hintText: 'e.g. Mga Serbisyo sa Pagbabakuna'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: colorHexCtrl,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Color (hex, e.g. BBDEFB or FFBBDEFB)',
                      hintText: 'BBDEFB',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: iconIndex,
                    decoration: inputDecoration.copyWith(labelText: 'Icon'),
                    dropdownColor: AdminUI.surface,
                    items: List.generate(
                        _iconNames.length,
                        (i) => DropdownMenuItem(
                            value: i,
                            child: Row(
                              children: [
                                Icon(_iconNameToIcon[_iconNames[i]] ?? Icons.circle),
                                const SizedBox(width: 8),
                                Text(_iconNames[i]),
                              ],
                            ))),
                    onChanged: (v) => setDialogState(() => iconIndex = v ?? 0),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: sortOrderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: inputDecoration.copyWith(labelText: 'Sort order'),
                  ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final sortOrderVal = int.tryParse(sortOrderCtrl.text.trim()) ?? sortOrder;
                  String hex = colorHexCtrl.text.trim().replaceFirst('#', '');
                  if (hex.length == 6) hex = 'FF$hex';
                  Navigator.of(ctx).pop(<String, dynamic>{
                    'title': title,
                    'color_hex': hex,
                    'icon_name': _iconNames[iconIndex],
                    'sort_order': sortOrderVal,
                  });
                },
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (isEdit) {
        await SupabaseService.client
            .from('primary_care_categories')
            .update({
          'title': result['title'],
          'color_hex': result['color_hex'],
          'icon_name': result['icon_name'],
          'sort_order': result['sort_order'],
        }).eq('id', existing['id']);
      } else {
        await SupabaseService.client.from('primary_care_categories').insert({
          'title': result['title'],
          'color_hex': result['color_hex'],
          'icon_name': result['icon_name'],
          'sort_order': result['sort_order'],
        });
      }
      if (!mounted) return;
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmArchiveCategory(BuildContext context, Map<String, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive category?'),
        content: Text(
            'This will hide "${cat['title']}" and its services from the service directory. You can unarchive later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Archive')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await SupabaseService.client
          .from('primary_care_categories')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', cat['id']);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _unarchiveCategory(Map<String, dynamic> cat) async {
    try {
      await SupabaseService.client
          .from('primary_care_categories')
          .update({'archived_at': null})
          .eq('id', cat['id']);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _archiveService(Map<String, dynamic> svc) async {
    try {
      await SupabaseService.client
          .from('primary_care_services')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', svc['id']);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _unarchiveService(Map<String, dynamic> svc) async {
    try {
      await SupabaseService.client
          .from('primary_care_services')
          .update({'archived_at': null})
          .eq('id', svc['id']);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmDeleteCategory(BuildContext context, Map<String, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
            'This will delete the category "${cat['title']}" and all ${_servicesForCategory(cat['id'] as String).length} services under it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AdminUI.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await SupabaseService.client
          .from('primary_care_categories')
          .delete()
          .eq('id', cat['id']);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  static num? _parsePrice(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = num.tryParse(v.trim());
    return (n != null && n > 0) ? n : null;
  }

  Future<void> _showAddOrEditService(BuildContext context,
      {String? categoryId, Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final catId = categoryId ?? existing?['category_id'] as String?;
    if (catId == null) return;
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] as String? ?? '');
    int sortOrder = (existing?['sort_order'] as int?) ?? _servicesForCategory(catId).length;
    final sortOrderCtrl = TextEditingController(text: sortOrder.toString());
    final existingPrice = existing?['price'];
    final priceStr = existingPrice == null
        ? ''
        : (existingPrice is num)
            ? (existingPrice > 0 ? existingPrice.toString() : '')
            : (existingPrice is String ? (existingPrice.trim().isEmpty ? '' : existingPrice) : '');
    final priceCtrl = TextEditingController(text: priceStr);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: AdminUI.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd), borderSide: const BorderSide(color: AdminUI.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd), borderSide: const BorderSide(color: AdminUI.indigo, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    // Pop dialog with form data first (no async in button), then save in caller.
    // This avoids popping the admin route if the dialog was already dismissed (e.g. barrier tap).
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit service' : 'Add service'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Service name',
                    hintText: 'e.g. Pagbabakuna sa mga Bata'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Description (optional)',
                    hintText: 'Short description of the service',
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: inputDecoration.copyWith(
                    labelText: 'Price (optional)',
                    hintText: 'Blank or 0 = Free',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: sortOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration.copyWith(labelText: 'Sort order'),
                  onChanged: (v) => sortOrder = int.tryParse(v) ?? 0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final order = int.tryParse(sortOrderCtrl.text.trim()) ?? sortOrder;
              final price = _parsePrice(priceCtrl.text);
              Navigator.of(ctx).pop(<String, dynamic>{
                'name': name,
                'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                'sort_order': order,
                'price': price,
              });
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (isEdit) {
        await SupabaseService.client
            .from('primary_care_services')
            .update({
          'name': result['name'],
          'description': result['description'],
          'sort_order': result['sort_order'],
          'price': result['price'],
        }).eq('id', existing['id']);
      } else {
        await SupabaseService.client.from('primary_care_services').insert({
          'category_id': catId,
          'name': result['name'],
          'description': result['description'],
          'sort_order': result['sort_order'],
          'price': result['price'],
        });
      }
      if (!mounted) return;
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmDeleteService(BuildContext context, Map<String, dynamic> svc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text('Remove "${svc['name']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AdminUI.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await SupabaseService.client
          .from('primary_care_services')
          .delete()
          .eq('id', svc['id']);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.services,
    required this.colorFromHex,
    required this.iconData,
    required this.isCategoryArchived,
    required this.onEditCategory,
    required this.onArchiveCategory,
    required this.onUnarchiveCategory,
    required this.onDeleteCategory,
    required this.onAddService,
    required this.onEditService,
    required this.onArchiveService,
    required this.onUnarchiveService,
    required this.onDeleteService,
    required this.isServiceArchived,
    required this.isServiceFree,
    required this.priceBadgeLabel,
  });

  final Map<String, dynamic> category;
  final List<Map<String, dynamic>> services;
  final Color Function(String) colorFromHex;
  final IconData iconData;
  final bool isCategoryArchived;
  final VoidCallback onEditCategory;
  final VoidCallback onArchiveCategory;
  final VoidCallback onUnarchiveCategory;
  final VoidCallback onDeleteCategory;
  final VoidCallback onAddService;
  final void Function(Map<String, dynamic>) onEditService;
  final void Function(Map<String, dynamic>) onArchiveService;
  final void Function(Map<String, dynamic>) onUnarchiveService;
  final void Function(Map<String, dynamic>) onDeleteService;
  final bool Function(Map<String, dynamic>) isServiceArchived;
  final bool Function(Map<String, dynamic>) isServiceFree;
  final String Function(Map<String, dynamic>) priceBadgeLabel;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final color = widget.colorFromHex(cat['color_hex'] as String? ?? 'BBDEFB');
    final title = cat['title'] as String? ?? '';
    final count = widget.services.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AdminUI.radiusLg),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.iconData, color: AdminUI.textPrimary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700, color: AdminUI.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count serbisyo',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AdminUI.textTertiary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      AdminRowActions(
                        iconSize: 20,
                        isArchived: widget.isCategoryArchived,
                        onEdit: widget.onEditCategory,
                        onArchive: widget.onArchiveCategory,
                        onUnarchive: widget.onUnarchiveCategory,
                        onDelete: widget.onDeleteCategory,
                      ),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AdminUI.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Services',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AdminUI.textTertiary, fontWeight: FontWeight.w600),
                        ),
                        Material(
                          color: AdminUI.indigo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: widget.onAddService,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 16, color: AdminUI.indigo),
                                  SizedBox(width: 4),
                                  Text('Add service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminUI.indigo)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.services.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No services in this category.',
                          style: TextStyle(fontSize: 13, color: AdminUI.textTertiary),
                        ),
                      )
                    else
                      ...widget.services.asMap().entries.map((e) {
                        final svc = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AdminUI.indigo.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w700, color: AdminUI.indigo),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  svc['name'] as String? ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AdminUI.textPrimary),
                                ),
                              ),
                              _PriceBadge(
                                isFree: widget.isServiceFree(svc),
                                label: widget.priceBadgeLabel(svc),
                              ),
                              AdminRowActions(
                                compact: true,
                                isArchived: widget.isServiceArchived(svc),
                                onEdit: () => widget.onEditService(svc),
                                onArchive: () => widget.onArchiveService(svc),
                                onUnarchive: () => widget.onUnarchiveService(svc),
                                onDelete: () => widget.onDeleteService(svc),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.isFree, required this.label});

  final bool isFree;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFree
            ? AdminUI.emerald.withOpacity(0.15)
            : AdminUI.textTertiary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AdminUI.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isFree ? AdminUI.emerald : AdminUI.textSecondary,
        ),
      ),
    );
  }
}
