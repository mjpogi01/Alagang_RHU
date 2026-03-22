import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

const _avatarColors = [
  AdminUI.indigo,
  AdminUI.emerald,
  AdminUI.amber,
  AdminUI.blue,
  AdminUI.rose,
];

/// Admin: view user accounts and families from Supabase.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.hideAppBar = false});

  final bool hideAppBar;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  int _segment = 0; // 0 = Users, 1 = Families
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _families = [];
  Map<String, int> _familyIdToMemberCount = {};
  Map<String, String> _userIdToFamilyId = {}; // decision_maker_user_id -> family id

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = SupabaseService.client;

      final profilesRes = await client.from('profiles').select('user_id, full_name, email, phone').order('created_at', ascending: false);
      final familiesRes = await client.from('families').select('id, decision_maker_user_id, family_code, name').order('created_at', ascending: false);
      final membersRes = await client.from('family_members').select('family_id');

      final profiles = List<Map<String, dynamic>>.from(profilesRes as List);
      final families = List<Map<String, dynamic>>.from(familiesRes as List);
      final members = List<Map<String, dynamic>>.from(membersRes as List);

      final Map<String, int> familyIdToCount = {};
      for (final m in members) {
        final fid = m['family_id'] as String?;
        if (fid != null) familyIdToCount[fid] = (familyIdToCount[fid] ?? 0) + 1;
      }

      final Map<String, String> userIdToFamilyId = {};
      for (final f in families) {
        final dm = f['decision_maker_user_id'] as String?;
        final id = f['id'] as String?;
        if (dm != null && id != null) userIdToFamilyId[dm] = id;
      }

      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _families = families;
        _familyIdToMemberCount = familyIdToCount;
        _userIdToFamilyId = userIdToFamilyId;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.hideAppBar) return body;
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'Users'),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AdminUI.red)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final search = _searchController.text.trim().toLowerCase();
    final filteredProfiles = search.isEmpty
        ? _profiles
        : _profiles.where((p) {
            final name = (p['full_name'] as String? ?? '').toLowerCase();
            final email = (p['email'] as String? ?? '').toLowerCase();
            final phone = (p['phone'] as String? ?? '').toLowerCase();
            return name.contains(search) || email.contains(search) || phone.contains(search);
          }).toList();
    final filteredFamilies = search.isEmpty
        ? _families
        : _families.where((f) {
            final code = (f['family_code'] as String? ?? '').toLowerCase();
            final name = (f['name'] as String? ?? '').toLowerCase();
            final dmId = f['decision_maker_user_id'] as String?;
            final dmName = dmId != null ? (_profiles.cast<Map<String, dynamic>?>().firstWhere((p) => p!['user_id'] == dmId, orElse: () => null)?['full_name'] as String? ?? '') : '';
            return code.contains(search) || name.contains(search) || dmName.toLowerCase().contains(search);
          }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + AppTheme.floatingNavBarClearance),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Users',
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
                        Text('Add User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AdminUI.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _segmentButton(context, 0, 'Users (${_profiles.length})'),
                _segmentButton(context, 1, 'Families (${_families.length})'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _segment == 0 ? 'Search users...' : 'Search families...',
              prefixIcon: const Icon(Icons.search, color: AdminUI.textTertiary, size: 20),
              filled: true,
              fillColor: AdminUI.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          if (_segment == 0) ..._buildUserCards(filteredProfiles),
          if (_segment == 1) ..._buildFamilyCards(filteredFamilies),
        ],
      ),
    );
  }

  List<Widget> _buildUserCards(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return [const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No users found')))];
    }
    return List.generate(list.length, (i) {
      final p = list[i];
      final userId = p['user_id'] as String?;
      final name = p['full_name'] as String? ?? '—';
      final email = p['email'] as String? ?? p['phone'] as String? ?? '—';
      final familyId = userId != null ? _userIdToFamilyId[userId] : null;
      final familyCount = familyId != null ? (_familyIdToMemberCount[familyId] ?? 0) : 0;
      final initials = _initials(name);
      return _UserCard(
        userId: userId,
        name: name,
        email: email,
        status: 'active',
        familyCount: familyCount,
        initials: initials,
        avatarColor: _avatarColors[i % _avatarColors.length],
        onEdit: () {},
        onDelete: () => _confirmDeleteUser(context, userId, name),
      );
    });
  }

  List<Widget> _buildFamilyCards(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return [const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No families found')))];
    }
    return List.generate(list.length, (i) {
      final f = list[i];
      final familyId = f['id'] as String?;
      final code = f['family_code'] as String? ?? '—';
      final familyName = f['name'] as String? ?? '—';
      final dmUserId = f['decision_maker_user_id'] as String?;
      final dmName = dmUserId != null
          ? (_profiles.cast<Map<String, dynamic>?>().firstWhere((p) => p!['user_id'] == dmUserId, orElse: () => null)?['full_name'] as String? ?? '—')
          : '—';
      final memberCount = familyId != null ? (_familyIdToMemberCount[familyId] ?? 0) : 0;
      return _FamilyCard(
        familyId: familyId,
        familyName: familyName,
        familyCode: code,
        decisionMakerName: dmName,
        memberCount: memberCount,
        onEdit: () {},
        onDelete: () {},
      );
    });
  }

  void _confirmDeleteUser(BuildContext context, String? userId, String name) {
    if (userId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('Remove "$name" from the app? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminUI.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Deleting the profile row; auth user deletion would require Admin API.
              try {
                await SupabaseService.client.from('profiles').delete().eq('user_id', userId);
                if (mounted) _loadData();
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  Widget _segmentButton(BuildContext context, int index, String label) {
    final selected = _segment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AdminUI.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AdminUI.indigo : AdminUI.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    this.userId,
    required this.name,
    required this.email,
    required this.status,
    required this.familyCount,
    required this.initials,
    required this.avatarColor,
    required this.onEdit,
    required this.onDelete,
  });

  final String? userId;
  final String name;
  final String email;
  final String status;
  final int familyCount;
  final String initials;
  final Color avatarColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: avatarColor.withOpacity(0.35), width: 2),
              ),
              alignment: Alignment.center,
              child: Text(initials, style: TextStyle(fontWeight: FontWeight.w700, color: avatarColor, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AdminUI.textPrimary)),
                  const SizedBox(height: 2),
                  Text(email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'active' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status == 'active' ? const Color(0xFF16A34A) : AdminUI.red)),
                      ),
                      const SizedBox(width: 8),
                      Text('$familyCount family member${familyCount != 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(onPressed: onEdit, icon: Icon(Icons.edit_outlined, size: 20, color: AdminUI.indigo.withOpacity(0.8)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
            IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline, size: 20, color: AdminUI.red.withOpacity(0.8)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          ],
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    this.familyId,
    required this.familyName,
    required this.familyCode,
    required this.decisionMakerName,
    required this.memberCount,
    required this.onEdit,
    required this.onDelete,
  });

  final String? familyId;
  final String familyName;
  final String familyCode;
  final String decisionMakerName;
  final int memberCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AdminUI.indigo.withOpacity(0.2),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AdminUI.indigo.withOpacity(0.35), width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.family_restroom, color: AdminUI.indigo, size: 22),
            ),
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(familyName.isEmpty ? 'Family' : familyName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AdminUI.textPrimary)),
                const SizedBox(height: 2),
                Text('Code: $familyCode', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary)),
                const SizedBox(height: 6),
                Text('Decision maker: $decisionMakerName · $memberCount member${memberCount != 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary, fontSize: 11)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: Icon(Icons.edit_outlined, size: 20, color: AdminUI.indigo.withOpacity(0.8)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline, size: 20, color: AdminUI.red.withOpacity(0.8)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
        ],
      ),
      ),
    );
  }
}
