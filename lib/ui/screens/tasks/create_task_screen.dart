import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/xp_constants.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/team_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  final UserModel user;
  const CreateTaskScreen({super.key, required this.user});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _diff = 5;
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  // Assignment state
  List<UserModel> _members = [];
  String? _assignedUserId;
  String? _assignedUserName;
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    if (widget.user.isTeamLead) _loadMembers();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final team = context.read<TeamProvider>().team;
      if (team == null) return;
      final repo = UserRepository();
      final list = <UserModel>[];
      for (final id in team.memberIds) {
        if (id == widget.user.id) continue;
        final u = await repo.getById(id);
        if (u != null) list.add(u);
      }
      if (mounted) setState(() => _members = list);
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _pickDeadline() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _deadline,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary)),
            child: child!));
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline),
        builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                    primary: AppColors.primary)),
            child: child!));
    if (t == null || !mounted) return;
    setState(() => _deadline =
        DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _create() async {
    final titleText = _title.text.trim();
    if (titleText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppColors.danger));
      return;
    }
    if (!widget.user.canCreateTasks) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Only Team Lead can create tasks'),
          backgroundColor: AppColors.danger));
      return;
    }
    setState(() => _loading = true);
    try {
      if (widget.user.hasTeam) {
        // Team task: save to SQLite + push to Firebase so all members see it
        final task = TaskModel(
          id: const Uuid().v4(),
          title: titleText,
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          difficulty: _diff,
          deadline: _deadline,
          createdBy: widget.user.id,
          teamId: widget.user.teamId!,
          assignedUserId: _assignedUserId,
          assignedUserName: _assignedUserName,
        );
        await context.read<TeamProvider>().createTask(task);
      } else {
        // Personal task: local SQLite only
        await context.read<TaskProvider>().createTask(
              userId: widget.user.id,
              title: titleText,
              description: _desc.text.trim().isEmpty
                  ? null
                  : _desc.text.trim(),
              difficulty: _diff,
              deadline: _deadline,
              teamId: widget.user.teamId,
              assignedUserId: _assignedUserId,
              assignedUserName: _assignedUserName,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  Widget _buildAssignSection() {
    if (_loadingMembers) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF3580FF),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Anyone option
        _AssignOption(
          emoji: '👥',
          name: 'Anyone in team',
          subtitle: 'Any member can act on this task',
          isSelected: _assignedUserId == null,
          onTap: () => setState(() {
            _assignedUserId = null;
            _assignedUserName = null;
          }),
        ),
        if (_members.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF191D30),
                borderRadius:
                    BorderRadius.all(Radius.circular(10)),
              ),
              child: const Text(
                'No other members in team yet.\nInvite members first.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF848A94),
                  height: 1.4,
                ),
              ),
            ),
          )
        else
          ...List.generate(_members.length, (i) {
            final m = _members[i];
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _AssignOption(
                emoji: m.avatarEmoji,
                name: m.name,
                subtitle: m.roleLabel,
                isSelected: _assignedUserId == m.id,
                onTap: () => setState(() {
                  _assignedUserId = m.id;
                  _assignedUserName = m.name;
                }),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.user.canCreateTasks) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context))),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    color: AppColors.danger, size: 48),
                SizedBox(height: 16),
                Text('Access Restricted',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Text(
                    'Only Team Lead can create tasks.\nComplete tasks assigned to you.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final xp = XpConstants.calculateXp(_diff);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close,
                color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context)),
        title: const Text('New Task',
            style:
                TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lbl('Title *'),
              const SizedBox(height: 6),
              _field(_title, 'What needs to be done?'),
              const SizedBox(height: 16),
              _lbl('Description (optional)'),
              const SizedBox(height: 6),
              _field(_desc, 'Details...', maxLines: 3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _lbl('Difficulty'),
                  Text('$_diff / 10',
                      style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              Slider(
                value: _diff.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceAlt,
                onChanged: (v) => setState(() => _diff = v.round()),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                        width: 0.5)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('XP reward if on time',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                    Text('+$xp XP',
                        style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 15)),
                  ],
                ),
              ),

              // ── Assign To (team leads only) ─────────────────────
              if (widget.user.isTeamLead) ...[
                const SizedBox(height: 20),
                _lbl('Assign To'),
                const SizedBox(height: 8),
                _buildAssignSection(),
              ],

              const SizedBox(height: 16),
              _lbl('Deadline'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.border, width: 0.5)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 15,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                        DateFormat('MMM d, yyyy — HH:mm')
                            .format(_deadline),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Create Task',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Text(t,
      style: const TextStyle(
          fontSize: 12, color: AppColors.textSecondary));

  Widget _field(TextEditingController c, String hint,
          {int maxLines = 1}) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.textMuted, fontSize: 13),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColors.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColors.border, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1)),
        ),
      );
}

// ─────────────────────────────────────────────
//  MEMBER OPTION WIDGET
// ─────────────────────────────────────────────
class _AssignOption extends StatelessWidget {
  final String emoji;
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _AssignOption({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  static const _selectedDeco = BoxDecoration(
    color: Color(0x203580FF),
    borderRadius: BorderRadius.all(Radius.circular(12)),
    border: Border.fromBorderSide(
        BorderSide(color: Color(0xFF3580FF), width: 1.5)),
  );

  static const _normalDeco = BoxDecoration(
    color: Color(0xFF191D30),
    borderRadius: BorderRadius.all(Radius.circular(12)),
    border: Border.fromBorderSide(
        BorderSide(color: Color(0xFF191D30))),
  );

  static const _nameStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static const _subtitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    color: Color(0xFF848A94),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: isSelected ? _selectedDeco : _normalDeco,
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF0A0C16),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: _nameStyle),
                Text(subtitle, style: _subtitleStyle),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF3580FF), size: 22),
        ]),
      ),
    );
  }
}
