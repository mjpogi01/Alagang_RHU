import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../models/family_member.dart';
import '../services/supabase_service.dart';

const List<String> _tagalogMonthNames = [
  'Enero',
  'Pebrero',
  'Marso',
  'Abril',
  'Mayo',
  'Hunyo',
  'Hulyo',
  'Agosto',
  'Setyembre',
  'Oktubre',
  'Nobyembre',
  'Disyembre',
];

String _formatTagalogDate(DateTime date) {
  return '${_tagalogMonthNames[date.month - 1]} ${date.day}, ${date.year}';
}

/// User & Family Profile Management: list of family members with add/edit/delete.
class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final List<FamilyMember> _members = [];
  bool _loading = true;
  String? _error;
  String? _familyId;

  static const Map<String, String> _relationOptions = {
    'anak': 'Anak',
    'apo': 'Apo',
    'asawa': 'Asawa',
    'pamangkin': 'Pamangkin',
    'ina': 'Ina',
    'ama': 'Ama',
    'lolo': 'Lolo',
    'lola': 'Lola',
    'tita': 'Tita',
    'tito': 'Tito',
    'lola_sa_tuhod': 'Lola sa tuhod',
    'lolo_sa_tuhod': 'Lolo sa tuhod',
    'pinsan': 'Pinsan',
  };

  FamilyMember _familyMemberFromRow(Map<String, dynamic> r) {
    final id = (r['id'] as String?) ?? '';
    final dobRaw = r['date_of_birth']?.toString().split('T').first;
    final dob = dobRaw != null ? DateTime.parse(dobRaw) : DateTime.now();
    final sexDb = (r['sex'] as String?) ?? 'other';
    final sex = Sex.values.firstWhere(
      (s) => s.name == sexDb,
      orElse: () => Sex.other,
    );
    final preg = r['pregnancy_status'] as bool?;
    final relation = (r['relation'] as String?)?.trim();
    final comorbid =
        (r['comorbidities'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];
    return FamilyMember(
      id: id,
      name: (r['name'] as String?)?.trim(),
      dateOfBirth: dob,
      sex: sex,
      relation: relation,
      pregnancyStatus: preg,
      comorbidities: comorbid,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = SupabaseService.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        setState(() {
          _loading = false;
          _error = 'Kailangan nakalag‑in upang pamahalaan ang pamilya.';
        });
        return;
      }

      String? familyId;
      try {
        final mem = await client
            .from('family_members')
            .select('family_id')
            .eq('user_id', uid)
            .maybeSingle();
        if (mem != null && mem['family_id'] != null) {
          familyId = mem['family_id'] as String;
        }
      } catch (_) {}

      if (familyId == null) {
        try {
          final fam = await client
              .from('families')
              .select('id')
              .eq('decision_maker_user_id', uid)
              .maybeSingle();
          if (fam != null && fam['id'] != null) {
            familyId = fam['id'] as String;
          }
        } catch (_) {}
      }

      if (familyId == null) {
        // Create a family for this user using the helper function.
        final createdId =
            await client.rpc('create_my_family', params: {'family_name': null});
        if (createdId is String) {
          familyId = createdId;
        } else if (createdId != null) {
          familyId = createdId.toString();
        }
      }

      if (familyId == null) {
        setState(() {
          _loading = false;
          _error = 'Hindi makuha o magawa ang pamilya. Subukang muli mamaya.';
        });
        return;
      }

      final res = await client
          .from('family_members')
          .select(
              'id, name, date_of_birth, sex, pregnancy_status, comorbidities, relation')
          .eq('family_id', familyId)
          .order('date_of_birth', ascending: true);
      final rows = List<Map<String, dynamic>>.from(res as List);
      final members = rows.map(_familyMemberFromRow).toList();

      if (!mounted) return;
      setState(() {
        _familyId = familyId;
        _members
          ..clear()
          ..addAll(members);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Hindi ma-load ang mga miyembro: $e';
      });
    }
  }

  void _addMember() async {
    if (_familyId == null) return;
    final result = await Navigator.of(context).push<FamilyMember?>(
      MaterialPageRoute(
        builder: (context) =>
            _AddEditFamilyMemberScreen(member: null, familyId: _familyId!),
      ),
    );
    if (result != null) {
      await _loadMembers();
    }
  }

  void _editMember(FamilyMember member) async {
    if (_familyId == null) return;
    final result = await Navigator.of(context).push<FamilyMember?>(
      MaterialPageRoute(
        builder: (context) => _AddEditFamilyMemberScreen(
          member: member,
          onDeleted: () => _deleteMember(member),
          familyId: _familyId!,
        ),
      ),
    );
    if (result != null) {
      await _loadMembers();
    }
  }

  Future<void> _deleteMember(FamilyMember member) async {
    try {
      await SupabaseService.client
          .from('family_members')
          .delete()
          .eq('id', member.id);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _members.removeWhere((m) => m.id == member.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text(AppStrings.familyMembersTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addMember),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(
                      AppTheme.scale(context, AppTheme.spacingXl),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        SizedBox(
                          height: AppTheme.scale(context, AppTheme.spacingMd),
                        ),
                        Text(
                          _error ?? AppStrings.noFamilyMembers,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppTheme.scale(context, AppTheme.spacingLg),
                AppTheme.scale(context, AppTheme.spacingMd),
                AppTheme.scale(context, AppTheme.spacingLg),
                AppTheme.scale(context, AppTheme.spacingLg) +
                    AppTheme.floatingNavBarClearance,
              ),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final m = _members[index];
                return _FamilyMemberCard(
                  member: m,
                  onTap: () => _editMember(m),
                );
              },
            ),
      floatingActionButton: _members.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addMember,
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({required this.member, required this.onTap});

  final FamilyMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Card(
      margin: EdgeInsets.only(bottom: scale * AppTheme.spacingMd),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
        child: Padding(
          padding: EdgeInsets.all(scale * AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24 * scale,
                    backgroundColor: AppTheme.primaryBlue.withValues(
                      alpha: 0.2,
                    ),
                    child: Text(
                      (member.name?.isNotEmpty == true ? member.name![0] : '?')
                          .toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 18 * scale,
                      ),
                    ),
                  ),
                  SizedBox(width: scale * AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name?.trim().isEmpty ?? true
                              ? 'Miyembro ng pamilya'
                              : member.name!,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          '${member.age} taong gulang · ${member.sex.label}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        if (member.relation != null &&
                            member.relation!.trim().isNotEmpty)
                          SizedBox(height: 2 * scale),
                        if (member.relation != null &&
                            member.relation!.trim().isNotEmpty)
                          Text(
                            'Relasyon: ${_FamilyMembersScreenState._relationOptions[member.relation] ?? member.relation}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                ],
              ),
              if (member.pregnancyStatus != null &&
                  member.sex == Sex.female) ...[
                SizedBox(height: scale * 6),
                Text(
                  'Pagbubuntis: ${member.pregnancyStatus! ? AppStrings.pregnancyYes : AppStrings.pregnancyNo}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (member.comorbidities.isNotEmpty) ...[
                SizedBox(height: scale * 6),
                Wrap(
                  spacing: 6 * scale,
                  runSpacing: 4 * scale,
                  children: member.comorbidities
                      .map(
                        (c) => Chip(
                          label: Text(
                            c,
                            style: TextStyle(fontSize: 11 * scale),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Add or edit family member form: name (optional), DOB, sex, pregnancy status, comorbidities.
class _AddEditFamilyMemberScreen extends StatefulWidget {
  const _AddEditFamilyMemberScreen(
      {this.member, this.onDeleted, required this.familyId});

  final FamilyMember? member;
  final VoidCallback? onDeleted;
  final String familyId;

  @override
  State<_AddEditFamilyMemberScreen> createState() =>
      _AddEditFamilyMemberScreenState();
}

class _AddEditFamilyMemberScreenState
    extends State<_AddEditFamilyMemberScreen> {
  final _nameController = TextEditingController();
  DateTime _dateOfBirth = DateTime.now().subtract(
    const Duration(days: 365 * 25),
  );
  Sex _sex = Sex.female;
  String? _relation;
  bool? _pregnancyStatus;
  final Set<String> _comorbidities = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      final m = widget.member!;
      _nameController.text = m.name ?? '';
      _dateOfBirth = m.dateOfBirth;
      _sex = m.sex;
      _relation = m.relation;
      _pregnancyStatus = m.pregnancyStatus;
      _comorbidities.addAll(m.comorbidities);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  FamilyMember _familyMemberFromRow(Map<String, dynamic> r) {
    final id = (r['id'] as String?) ?? '';
    final dobRaw = r['date_of_birth']?.toString().split('T').first;
    final dob = dobRaw != null ? DateTime.parse(dobRaw) : DateTime.now();
    final sexDb = (r['sex'] as String?) ?? 'other';
    final sex = Sex.values.firstWhere(
      (s) => s.name == sexDb,
      orElse: () => Sex.other,
    );
    final preg = r['pregnancy_status'] as bool?;
    final relation = (r['relation'] as String?)?.trim();
    final comorbid =
        (r['comorbidities'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];
    return FamilyMember(
      id: id,
      name: (r['name'] as String?)?.trim(),
      dateOfBirth: dob,
      sex: sex,
      relation: relation,
      pregnancyStatus: preg,
      comorbidities: comorbid,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final list = _comorbidities.contains('Wala')
          ? <String>[]
          : _comorbidities.where((c) => c != 'Wala').toList();
      final payload = {
        'family_id': widget.familyId,
        'name': _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        'date_of_birth': _dateOfBirth.toIso8601String(),
        'sex': _sex.name,
        'relation': _relation,
        'pregnancy_status': _sex == Sex.female ? _pregnancyStatus : null,
        'comorbidities': list,
      };
      final client = SupabaseService.client;
      Map<String, dynamic> row;
      if (widget.member == null) {
        final res = await client
            .from('family_members')
            .insert(payload)
            .select()
            .single();
        row = Map<String, dynamic>.from(res as Map);
      } else {
        final res = await client
            .from('family_members')
            .update(payload)
            .eq('id', widget.member!.id)
            .select()
            .maybeSingle();
        row = Map<String, dynamic>.from(
            (res as Map?) ?? <String, dynamic>{'id': widget.member!.id});
        row['date_of_birth'] ??=
            widget.member!.dateOfBirth.toIso8601String();
        row['sex'] ??= widget.member!.sex.name;
        row['name'] ??= widget.member!.name;
        row['relation'] ??= widget.member!.relation;
        row['pregnancy_status'] ??= widget.member!.pregnancyStatus;
        row['comorbidities'] ??= widget.member!.comorbidities;
      }
      final member = _familyMemberFromRow(row);
      if (!mounted) return;
      Navigator.of(context).pop(member);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi na-save ang miyembro: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  void _confirmDelete() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(AppStrings.deleteMemberConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) {
        widget.onDeleted?.call();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    final isEditing = widget.member != null;
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: Text(
          isEditing ? AppStrings.editFamilyMember : AppStrings.addFamilyMember,
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(scale * AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.nameOptional,
                hintText: AppStrings.nameHintFamily,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.searchBarBackground,
              ),
            ),
            SizedBox(height: scale * AppTheme.spacingMd),
            ListTile(
              title: const Text(AppStrings.dateOfBirth),
              subtitle: Text(_formatTagalogDate(_dateOfBirth)),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.borderLight),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _dateOfBirth = date);
              },
            ),
            SizedBox(height: scale * AppTheme.spacingMd),
            DropdownButtonFormField<Sex>(
              initialValue: _sex,
              decoration: InputDecoration(
                labelText: AppStrings.sex,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.searchBarBackground,
              ),
              items: Sex.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() {
                _sex = v ?? _sex;
                if (_sex != Sex.female) _pregnancyStatus = null;
              }),
            ),
            SizedBox(height: scale * AppTheme.spacingMd),
            DropdownButtonFormField<String?>(
              value: _relation,
              decoration: InputDecoration(
                labelText: AppStrings.memberRelation,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.searchBarBackground,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(AppStrings.memberRelationSelect),
                ),
                ..._FamilyMembersScreenState._relationOptions.entries
                    .map(
                  (e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                    .toList(),
              ],
              onChanged: (v) => setState(() => _relation = v),
            ),
            if (_sex == Sex.female) ...[
              SizedBox(height: scale * AppTheme.spacingMd),
              const Text(AppStrings.pregnancyStatus),
              SizedBox(height: scale * 4),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Oo'),
                    icon: Icon(Icons.check),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Hindi'),
                    icon: Icon(Icons.close),
                  ),
                ],
                selected: {_pregnancyStatus},
                onSelectionChanged: (s) =>
                    setState(() => _pregnancyStatus = s.first),
              ),
            ],
            SizedBox(height: scale * AppTheme.spacingMd),
            Text(AppStrings.comorbidities),
            SizedBox(height: scale * 6),
            Wrap(
              spacing: 6 * scale,
              runSpacing: 6 * scale,
              children: kComorbidityOptions.map((opt) {
                final selected = _comorbidities.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (opt == 'Wala') {
                        if (v) _comorbidities.clear();
                        _comorbidities.add('Wala');
                      } else {
                        _comorbidities.remove('Wala');
                        if (v) {
                          _comorbidities.add(opt);
                        } else {
                          _comorbidities.remove(opt);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: scale * AppTheme.spacingXxl),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: scale * 14),
              ),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
