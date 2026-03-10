import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../models/family_member.dart';

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

  void _addMember() async {
    final result = await Navigator.of(context).push<FamilyMember?>(
      MaterialPageRoute(
        builder: (context) => _AddEditFamilyMemberScreen(member: null),
      ),
    );
    if (result != null) setState(() => _members.add(result));
  }

  void _editMember(FamilyMember member) async {
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index < 0) return;
    final result = await Navigator.of(context).push<FamilyMember?>(
      MaterialPageRoute(
        builder: (context) => _AddEditFamilyMemberScreen(
          member: member,
          onDeleted: () => _deleteMember(member),
        ),
      ),
    );
    if (result != null) setState(() => _members[index] = result);
  }

  void _deleteMember(FamilyMember member) {
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
      body: _members.isEmpty
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
                      AppStrings.noFamilyMembers,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
  const _AddEditFamilyMemberScreen({this.member, this.onDeleted});

  final FamilyMember? member;
  final VoidCallback? onDeleted;

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
  bool? _pregnancyStatus;
  final Set<String> _comorbidities = {};

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      final m = widget.member!;
      _nameController.text = m.name ?? '';
      _dateOfBirth = m.dateOfBirth;
      _sex = m.sex;
      _pregnancyStatus = m.pregnancyStatus;
      _comorbidities.addAll(m.comorbidities);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final list = _comorbidities.contains('Wala')
        ? <String>[]
        : _comorbidities.where((c) => c != 'Wala').toList();
    final member = FamilyMember(
      id: widget.member?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      sex: _sex,
      pregnancyStatus: _sex == Sex.female ? _pregnancyStatus : null,
      comorbidities: list,
    );
    Navigator.of(context).pop(member);
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
